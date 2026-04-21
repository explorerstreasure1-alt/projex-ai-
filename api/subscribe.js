// Lemonsqueezy Subscription Handler
export default async function handler(req, res) {
  if (req.method === 'POST') {
    const { userId, variantId } = req.body;

    try {
      // Create checkout session
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
        })
      });

      const data = await response.json();
      res.status(200).json({ checkoutUrl: data.data.attributes.url });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  } else if (req.method === 'GET') {
    // Verify subscription status
    const { userId } = req.query;
    
    try {
      const response = await fetch(
        `https://api.lemonsqueezy.com/v1/subscriptions?filter[user_id]=${userId}`,
        {
          headers: {
            'Accept': 'application/vnd.api+json',
            'Authorization': `Bearer ${process.env.LEMONSQUEEZY_API_KEY}`
          }
        }
      );

      const data = await response.json();
      const active = data.data?.some(sub => sub.attributes.status === 'active');
      
      res.status(200).json({ 
        subscribed: active,
        subscriptions: data.data
      });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  } else {
    res.status(405).json({ error: 'Method not allowed' });
  }
}
