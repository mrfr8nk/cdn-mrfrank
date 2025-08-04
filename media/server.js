require('dotenv').config();
const express = require('express');
const multer = require('multer');
const { Octokit } = require('octokit');
const path = require('path');
const fs = require('fs');
const axios = require('axios');

const app = express();
const upload = multer({ dest: 'tmp/' });

const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });

// Persistent File Store
const fileStore = {
  _map: new Map(),
  
  async init() {
    try {
      console.log('Initializing file store from GitHub...');
      const { data } = await octokit.rest.repos.getContent({
        owner: process.env.GITHUB_OWNER,
        repo: 'cdn-mrfrank',
        path: '',
        ref: 'main'
      });

      this._map.clear();
      const files = data.filter(item => item.type === 'file');
      
      files.forEach(file => {
        this._map.set(file.path, {
          githubUrl: file.download_url,
          cdnUrl: `${process.env.CDN_DOMAIN}/${file.path}`,
          size: file.size,
          sha: file.sha
        });
      });
      
      console.log(`Loaded ${files.length} files into memory`);
    } catch (error) {
      console.error('Error initializing file store:', error);
    }
  },

  get(path) {
    return this._map.get(path);
  },

  set(path, value) {
    this._map.set(path, value);
  },

  delete(path) {
    this._map.delete(path);
  },

  getAll() {
    return Array.from(this._map.entries());
  }
};

// Initialize file store on server start
fileStore.init();

// Refresh file store periodically (every hour)
setInterval(() => fileStore.init(), 3600000);

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Upload endpoint
app.post('/upload', upload.single('file'), async (req, res) => {
  try {
    const customName = req.body.customName || path.parse(req.file.originalname).name;
    const fileExt = path.extname(req.file.originalname);
    const finalFilename = `${customName}${fileExt}`;
    
    // Clean and format storage path
    let storagePath = req.body.path || 'media/';
    storagePath = storagePath.replace(/^\/|\/$/g, '') + '/';
    
    const filePath = `${storagePath}${finalFilename}`;
    const fileContent = fs.readFileSync(req.file.path, { encoding: 'base64' });

    // Upload to GitHub
    const { data } = await octokit.rest.repos.createOrUpdateFileContents({
      owner: process.env.GITHUB_OWNER,
      repo: 'cdn-mrfrank',
      path: filePath,
      message: `Upload ${finalFilename}`,
      content: fileContent,
      branch: 'main'
    });

    fs.unlinkSync(req.file.path);

    // Update file store
    fileStore.set(filePath, {
      githubUrl: data.content.download_url,
      cdnUrl: `${process.env.CDN_DOMAIN}/${filePath}`,
      size: req.file.size,
      sha: data.content.sha
    });

    res.json({
      success: true,
      cdnUrl: `${process.env.CDN_DOMAIN}/${filePath}`,
      filename: finalFilename,
      path: filePath
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ 
      success: false,
      error: error.message,
      details: error.response?.data 
    });
  }
});

// Get all files (for admin)
app.get('/admin/files', async (req, res) => {
  try {
    const files = [];
    
    for (const [path, file] of fileStore.getAll()) {
      try {
        const commitData = await octokit.rest.repos.listCommits({
          owner: process.env.GITHUB_OWNER,
          repo: 'cdn-mrfrank',
          path: path,
          per_page: 1
        });
        
        files.push({
          name: path.split('/').pop(),
          path: path,
          size: file.size,
          url: file.cdnUrl,
          download_url: file.githubUrl,
          uploaded_at: commitData.data[0]?.commit?.author?.date || new Date().toISOString(),
          type: path.split('.').pop().toLowerCase(),
          sha: file.sha
        });
      } catch (error) {
        console.error(`Error getting commit data for ${path}:`, error);
      }
    }

    res.json({ files });
  } catch (error) {
    console.error('Admin files error:', error);
    res.status(500).json({ error: 'Failed to fetch files' });
  }
});

// Delete file (for admin)
app.delete('/admin/files/:path', async (req, res) => {
  try {
    const filePath = decodeURIComponent(req.params.path);
    const fileInfo = fileStore.get(filePath);

    if (!fileInfo) {
      return res.status(404).json({ error: 'File not found in store' });
    }

    await octokit.rest.repos.deleteFile({
      owner: process.env.GITHUB_OWNER,
      repo: 'cdn-mrfrank',
      path: filePath,
      message: `Deleted ${filePath}`,
      sha: fileInfo.sha,
      branch: 'main'
    });

    fileStore.delete(filePath);
    res.json({ success: true });
  } catch (error) {
    console.error('Delete error:', error);
    res.status(500).json({ error: 'Failed to delete file' });
  }
});

// File serving endpoint with GitHub fallback
app.get('/*', async (req, res) => {
  try {
    const requestPath = req.path.substring(1);
    const fileInfo = fileStore.get(requestPath);

    if (fileInfo) {
      return pipeFromGitHub(fileInfo.githubUrl, res);
    }

    // Fallback to GitHub directly
    try {
      const { data } = await octokit.rest.repos.getContent({
        owner: process.env.GITHUB_OWNER,
        repo: 'cdn-mrfrank',
        path: requestPath,
        ref: 'main'
      });

      if (data.type === 'file') {
        // Add to file store for future requests
        fileStore.set(requestPath, {
          githubUrl: data.download_url,
          cdnUrl: `${process.env.CDN_DOMAIN}/${requestPath}`,
          size: data.size,
          sha: data.sha
        });

        return pipeFromGitHub(data.download_url, res);
      }
    } catch (fallbackError) {
      console.error('Fallback error:', fallbackError);
      return res.status(404).send('File not found');
    }

    res.status(404).send('File not found');
  } catch (error) {
    console.error('File serving error:', error);
    res.status(500).send('Error retrieving file');
  }
});

// Helper function to stream files from GitHub
async function pipeFromGitHub(githubUrl, res) {
  try {
    const response = await axios.get(githubUrl, {
      responseType: 'stream'
    });

    // Set content type based on extension
    const ext = path.extname(githubUrl).toLowerCase();
    const contentType = getContentType(ext);
    if (contentType) {
      res.set('Content-Type', contentType);
    }

    response.data.pipe(res);
  } catch (error) {
    throw error;
  }
}

// Health check endpoint
app.get('/api/status', (req, res) => {
  res.json({ 
    status: 'active',
    repo: 'cdn-mrfrank',
    owner: process.env.GITHUB_OWNER,
    filesInMemory: fileStore._map.size,
    cdnDomain: process.env.CDN_DOMAIN
  });
});

// Content type mapping
function getContentType(ext) {
  const types = {
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.gif': 'image/gif',
    '.webp': 'image/webp',
    '.svg': 'image/svg+xml',
    '.js': 'application/javascript',
    '.mjs': 'application/javascript',
    '.cjs': 'application/javascript',
    '.css': 'text/css',
    '.html': 'text/html',
    '.json': 'application/json',
    '.txt': 'text/plain',
    '.pdf': 'application/pdf',
    '.zip': 'application/zip',
    '.mp3': 'audio/mpeg',
    '.mp4': 'video/mp4'
  };
  return types[ext] || 'application/octet-stream';
}

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`CDN Domain: ${process.env.CDN_DOMAIN}`);
  console.log(`GitHub Repo: cdn-mrfrank`);
  console.log(`Admin UI: http://localhost:${PORT}/admin.html`);
});
