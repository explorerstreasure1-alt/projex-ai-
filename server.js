require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('.'));

// Supabase client
const supabaseUrl = process.env.SUPABASE_URL || 'https://dbwhzmpfgfgemifiuhrp.supabase.co';
const supabaseKey = process.env.SUPABASE_ANON_KEY || 'sb_publishable_aFj8bK_5bV-6CuDlpJDLMw_UmJPDXY1';
const supabase = createClient(supabaseUrl, supabaseKey);

// AI API endpoints
app.post('/api/groq', async (req, res) => {
  try {
    const { prompt, system } = req.body;

    if (!prompt) {
      return res.status(400).json({ success: false, error: 'Prompt is required' });
    }

    const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${process.env.GROQ_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'llama2-70b-4096',
        messages: [
          { role: 'system', content: system || 'You are a helpful assistant.' },
          { role: 'user', content: prompt }
        ],
        temperature: 0.7,
        max_tokens: 1024
      })
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.message || `HTTP ${response.status}`);
    }

    const data = await response.json();
    const content = data.choices?.[0]?.message?.content || '';

    res.json({ success: true, content });
  } catch (error) {
    console.error('Groq API Error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/mistral', async (req, res) => {
  try {
    const { prompt, system } = req.body;

    if (!prompt) {
      return res.status(400).json({ success: false, error: 'Prompt is required' });
    }

    const response = await fetch('https://api.mistral.ai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${process.env.MISTRAL_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'mistral-tiny',
        messages: [
          { role: 'system', content: system || 'You are a helpful assistant.' },
          { role: 'user', content: prompt }
        ],
        temperature: 0.7,
        max_tokens: 1024
      })
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.message || `HTTP ${response.status}`);
    }

    const data = await response.json();
    const content = data.choices?.[0]?.message?.content || '';

    res.json({ success: true, content });
  } catch (error) {
    console.error('Mistral API Error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/generate-image', async (req, res) => {
  try {
    const { prompt, provider } = req.body;

    if (!prompt) {
      return res.status(400).json({ success: false, error: 'Prompt is required' });
    }

    // Using a placeholder image service for demo
    // In production, integrate with DALL-E, Stable Diffusion, or similar
    const imageUrl = `https://placehold.co/512x512/1a1a2e/fff?text=${encodeURIComponent(prompt.substring(0, 30))}`;

    res.json({ success: true, imageUrl });
  } catch (error) {
    console.error('Image Generation Error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Serve index.html for all other routes (SPA)
app.get('*', (req, res) => {
  res.sendFile(__dirname + '/index.html');
});

app.listen(PORT, () => {
  console.log(`PROJEX AI Server running on port ${PORT}`);
  console.log(`AI Endpoints: /api/groq, /api/mistral, /api/generate-image`);
});
