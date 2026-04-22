// Lemonsqueezy Subscription Handler
export default async function handler(req, res) {
  // Add CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method === 'POST') {
    const { userId, variantId } = req.body;

    // Request validation
    if (!userId || typeof userId !== 'string') {
      return res.status(400).json({ error: 'userId is required and must be a string' });
    }

    if (!variantId || typeof variantId !== 'string') {
      return res.status(400).json({ error: 'variantId is required and must be a string' });
    }

    if (!process.env.LEMONSQUEEZY_API_KEY || !process.env.LEMONSQUEEZY_STORE_ID) {
      console.error('LemonSqueezy credentials not configured');
      return res.status(500).json({ error: 'Server configuration error' });
    }

    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 15000); // 15 second timeout

      const response = await fetch('https://api.lemonsqueezy.com/v1/checkouts', {
        method: 'POST',
        headers: {
          'Accept': 'application/vnd.api+json',
          'Content-Type': 'application/vnd.api+json',
          'Authorization': `Bearer ${process.env.LEMONSQUEEZY_API_KEY}`
        },
        body: JSON.stringify({
          data: {
            type: 'checkouts',
            attributes: {
              checkout_data: {
                custom: {
                  user_id: userId
                }
              }
            },
            relationships: {
              store: {
                data: {
                  type: 'stores',
                  id: process.env.LEMONSQUEEZY_STORE_ID
                }
              },
              variant: {
                data: {
                  type: 'variants',
                  id: variantId
                }
              }
            }
          }
        }),
        signal: controller.signal
      });

      clearTimeout(timeout);

      if (!response.ok) {
        const error = await response.json();
        console.error('LemonSqueezy Error:', error);
        throw new Error(error.errors?.[0]?.detail || 'Checkout creation failed');
      }

      const data = await response.json();
      res.status(200).json({
        success: true,
        checkoutUrl: data.data.attributes.url
      });
    } catch (error) {
      console.error('Subscription Error:', error);

      if (error.name === 'AbortError') {
        return res.status(504).json({ error: 'Request timeout' });
      }

      res.status(500).json({
        success: false,
        error: error.message || 'Internal server error'
      });
    }
  } else if (req.method === 'GET') {
    // Verify subscription status
    const { userId } = req.query;

    if (!userId) {
      return res.status(400).json({ error: 'userId is required' });
    }

    if (!process.env.LEMONSQUEEZY_API_KEY) {
      console.error('LEMONSQUEEZY_API_KEY not configured');
      return res.status(500).json({ error: 'Server configuration error' });
    }

    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 15000); // 15 second timeout

      const response = await fetch(
        `https://api.lemonsqueezy.com/v1/subscriptions?filter[user_id]=${userId}`,
        {
          headers: {
            'Accept': 'application/vnd.api+json',
            'Authorization': `Bearer ${process.env.LEMONSQUEEZY_API_KEY}`
          },
          signal: controller.signal
        }
      );

      clearTimeout(timeout);

      if (!response.ok) {
        const error = await response.json();
        console.error('LemonSqueezy Error:', error);
        throw new Error('Subscription check failed');
      }

      const data = await response.json();
      const active = data.data?.some(sub => sub.attributes.status === 'active');

      res.status(200).json({
        success: true,
        subscribed: active,
        subscriptions: data.data
      });
    } catch (error) {
      console.error('Subscription Check Error:', error);

      if (error.name === 'AbortError') {
        return res.status(504).json({ error: 'Request timeout' });
      }

      res.status(500).json({
        success: false,
        error: error.message || 'Internal server error'
      });
    }
  } else {
    res.status(405).json({ error: 'Method not allowed' });
  }
}
