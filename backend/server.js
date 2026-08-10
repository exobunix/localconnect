const express = require('express');
const http = require('http');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const { WebSocketServer, WebSocket } = require('ws');
const path = require('path');
const fs = require('fs');

// Load environment variables
const envPath = path.join(__dirname, '../atlas-credentials (4).env');
if (fs.existsSync(envPath)) {
  const envConfig = dotenv.parse(fs.readFileSync(envPath));
  for (const k in envConfig) {
    process.env[k] = envConfig[k];
  }
} else {
  dotenv.config();
}

const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/localconnect';
const PORT = process.env.PORT || 3000;

const app = express();
app.use(cors());
app.use(express.json());

// Connect to MongoDB
mongoose.connect(mongoUri)
  .then(() => console.log('Connected to MongoDB Atlas'))
  .catch(err => console.error('MongoDB connection error:', err));

// Define generic flexible schemas
const collections = [
  'user_profiles',
  'service_providers',
  'orders',
  'notifications',
  'conversations',
  'messages',
  'reviews',
  'saved_addresses',
  'payment_methods',
  'order_preferences',
  'order_tracking',
  'complaints',
  'bookings',
  'support_tickets',
  'provider_earnings',
  'provider_subscriptions'
];

const models = {};
collections.forEach(name => {
  const schema = new mongoose.Schema({
    id: { type: String, unique: true },
    created_at: { type: Date, default: Date.now },
    updated_at: { type: Date, default: Date.now }
  }, { strict: false, versionKey: false });
  
  // Custom uuid/id generation for compatibility
  schema.pre('save', function(next) {
    if (!this.id) {
      this.id = new mongoose.Types.ObjectId().toString();
    }
    next();
  });
  
  models[name] = mongoose.model(name, schema, name);
});

// Simple Auth Emulation System
const users = [];

app.post('/auth/v1/signup', async (req, res) => {
  const { email, password, data } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }
  
  const existing = users.find(u => u.email === email);
  if (existing) {
    return res.status(400).json({ error: 'User already exists' });
  }

  const userId = new mongoose.Types.ObjectId().toString();
  const newUser = {
    id: userId,
    email,
    password,
    user_metadata: data || {},
    created_at: new Date().toISOString()
  };
  users.push(newUser);

  // Automatically seed the user profile record
  try {
    await models['user_profiles'].create({
      id: userId,
      email,
      full_name: data?.full_name || email.split('@')[0],
      phone: data?.phone || '',
      role: data?.role || 'customer',
      city: 'Pune',
      is_active: true
    });
  } catch (err) {
    console.error('Error seeding profile on signup:', err);
  }

  res.status(200).json({
    user: {
      id: userId,
      email,
      user_metadata: data || {}
    },
    session: {
      access_token: `mock-token-${userId}`,
      token_type: 'bearer',
      expires_in: 3600,
      user: {
        id: userId,
        email,
        user_metadata: data || {}
      }
    }
  });
});

app.post('/auth/v1/token', async (req, res) => {
  const { email, password, provider, name } = req.body;
  
  // Handle password grant
  let user = users.find(u => u.email === email && u.password === password);
  
  // Handle Google OAuth check
  if (provider === 'google') {
    const profile = await models['user_profiles'].findOne({ email });
    if (!profile) {
      return res.status(404).json({ error: 'USER_NOT_REGISTERED', email });
    }
    
    // Auto-seed session if not active in users memory cache
    if (!user) {
      user = {
        id: profile.id,
        email,
        password: password || 'google-oauth-pass',
        user_metadata: { full_name: profile.full_name, role: profile.role },
        created_at: new Date().toISOString()
      };
      users.push(user);
    }
  }

  if (!user) {
    // If not found, let's check if there is a profile or auto-create a mock user for convenience (for testing demo accounts)
    const profile = await models['user_profiles'].findOne({ email });
    if (profile) {
      const mockUser = {
        id: profile.id,
        email,
        password: 'password', // Default fallback
        user_metadata: { full_name: profile.full_name, role: profile.role },
        created_at: new Date().toISOString()
      };
      users.push(mockUser);
      return res.status(200).json({
        user: mockUser,
        session: {
          access_token: `mock-token-${profile.id}`,
          user: mockUser
        }
      });
    }
    return res.status(400).json({ error: 'Invalid email or password' });
  }

  res.status(200).json({
    user,
    session: {
      access_token: `mock-token-${user.id}`,
      token_type: 'bearer',
      expires_in: 3600,
      user
    }
  });
});

app.get('/auth/v1/user', (req, res) => {
  const authHeader = req.headers.authorization;
  if (!authHeader) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  const token = authHeader.replace('Bearer ', '');
  const userId = token.replace('mock-token-', '');
  const user = users.find(u => u.id === userId);
  
  if (!user) {
    return res.status(401).json({ error: 'User session not found' });
  }
  
  res.status(200).json(user);
});

app.post('/auth/v1/logout', (req, res) => {
  res.status(200).json({ message: 'Logged out successfully' });
});

// Helper for parsing PostgREST filters
function parseFilters(query) {
  const mongoQuery = {};
  for (const key in query) {
    if (['select', 'order', 'limit', 'offset'].includes(key)) continue;
    
    const value = query[key];
    if (typeof value === 'string') {
      const [op, ...rest] = value.split('.');
      const valStr = rest.join('.');
      
      switch (op) {
        case 'eq':
          // Handle 'null' string
          mongoQuery[key] = valStr === 'null' ? null : valStr;
          break;
        case 'neq':
          mongoQuery[key] = { $ne: valStr === 'null' ? null : valStr };
          break;
        case 'gt':
          mongoQuery[key] = { $gt: isNaN(valStr) ? valStr : Number(valStr) };
          break;
        case 'gte':
          mongoQuery[key] = { $gte: isNaN(valStr) ? valStr : Number(valStr) };
          break;
        case 'lt':
          mongoQuery[key] = { $lt: isNaN(valStr) ? valStr : Number(valStr) };
          break;
        case 'lte':
          mongoQuery[key] = { $lte: isNaN(valStr) ? valStr : Number(valStr) };
          break;
        case 'like':
        case 'ilike':
          mongoQuery[key] = { $regex: valStr.replace(/%/g, '.*'), $options: 'i' };
          break;
        case 'is':
          if (valStr === 'null') mongoQuery[key] = null;
          break;
        case 'in':
          // value is formatted as (val1,val2,...)
          const items = valStr.replace(/[()]/g, '').split(',');
          mongoQuery[key] = { $in: items };
          break;
        default:
          mongoQuery[key] = value;
      }
    }
  }
  return mongoQuery;
}

// REST PostgREST emulation endpoints
app.get('/rest/v1/:table', async (req, res) => {
  const { table } = req.params;
  const model = models[table];
  if (!model) return res.status(404).json({ error: `Table ${table} not found` });

  try {
    const filter = parseFilters(req.query);
    let dbQuery = model.find(filter);
    
    // Sort
    if (req.query.order) {
      const [col, dir] = req.query.order.split('.');
      dbQuery = dbQuery.sort({ [col]: dir === 'desc' ? -1 : 1 });
    }
    
    // Limit
    if (req.query.limit) {
      dbQuery = dbQuery.limit(Number(req.query.limit));
    }
    
    const results = await dbQuery.exec();
    
    // Header for maybeSingle
    const prefer = req.headers['prefer'] || '';
    if (prefer.includes('handling=strict') || req.query.limit === '1') {
      return res.status(200).json(results[0] || null);
    }
    
    res.status(200).json(results);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/rest/v1/:table', async (req, res) => {
  const { table } = req.params;
  const model = models[table];
  if (!model) return res.status(404).json({ error: `Table ${table} not found` });

  try {
    const isUpsert = (req.headers['prefer'] || '').includes('resolution=merge-duplicates');
    
    let result;
    if (isUpsert) {
      // Find matching keys or generate unique id if not present
      const doc = req.body;
      const id = doc.id || doc.user_id || new mongoose.Types.ObjectId().toString();
      result = await model.findOneAndUpdate(
        { id },
        { $set: doc },
        { upsert: true, new: true, runValidators: true }
      );
    } else {
      if (Array.isArray(req.body)) {
        result = await model.insertMany(req.body.map(item => ({
          id: new mongoose.Types.ObjectId().toString(),
          ...item
        })));
      } else {
        result = await model.create({
          id: new mongoose.Types.ObjectId().toString(),
          ...req.body
        });
      }
    }
    
    broadcast(table, 'INSERT', result);
    
    res.status(201).json(Array.isArray(result) ? result : [result]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.patch('/rest/v1/:table', async (req, res) => {
  const { table } = req.params;
  const model = models[table];
  if (!model) return res.status(404).json({ error: `Table ${table} not found` });

  try {
    const filter = parseFilters(req.query);
    const updates = req.body;
    
    // Find matching documents to broadcast update later
    const docs = await model.find(filter);
    
    await model.updateMany(filter, { $set: updates });
    
    const updatedDocs = await model.find(filter);
    updatedDocs.forEach(doc => {
      broadcast(table, 'UPDATE', doc);
    });
    
    res.status(200).json(updatedDocs);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/rest/v1/:table', async (req, res) => {
  const { table } = req.params;
  const model = models[table];
  if (!model) return res.status(404).json({ error: `Table ${table} not found` });

  try {
    const filter = parseFilters(req.query);
    const docs = await model.find(filter);
    
    await model.deleteMany(filter);
    
    docs.forEach(doc => {
      broadcast(table, 'DELETE', doc);
    });
    
    res.status(200).json(docs);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// WebSocket Server & Realtime Logic
const server = http.createServer(app);
const wss = new WebSocketServer({ server });

const clients = new Set();

wss.on('connection', (ws) => {
  console.log('Realtime client connected');
  clients.add(ws);
  
  ws.subscriptions = [];
  
  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message);
      
      // Replicate Supabase Realtime channel subscription format
      if (data.event === 'phx_join') {
        const topic = data.topic; // format: realtime:public:table_name:col=eq.val
        const sub = {
          topic,
          ref: data.ref
        };
        ws.subscriptions.push(sub);
        
        ws.send(JSON.stringify({
          event: 'phx_reply',
          topic,
          payload: { status: 'ok' },
          ref: data.ref
        }));
      }
    } catch (err) {
      console.error('WebSocket message error:', err);
    }
  });
  
  ws.on('close', () => {
    console.log('Realtime client disconnected');
    clients.delete(ws);
  });
});

function broadcast(table, eventType, record) {
  const payload = {
    event: 'postgres_changes',
    topic: `realtime:public:${table}`,
    payload: {
      data: record,
      event: eventType,
      schema: 'public',
      table
    }
  };
  
  const msg = JSON.stringify(payload);
  clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      // Check client subscriptions
      const hasSub = client.subscriptions.some(sub => 
        sub.topic.includes(`realtime:public:${table}`) || 
        sub.topic.includes(`realtime:public:${table}:`)
      );
      if (hasSub) {
        client.send(msg);
      }
    }
  });
}

// Start Server
server.listen(PORT, () => {
  console.log(`LocalConnect Backend listening on port ${PORT}`);
});
