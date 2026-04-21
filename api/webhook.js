// Lemonsqueezy Webhook Handler
export const config = {
  api: {
    bodyParser: false
  }
};

import crypto from 'crypto';

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const rawBody = await getRawBody(req);
    const signature = req.headers['x-signature'];

    // Verify webhook signature
    const computed = crypto
      .createHmac('sha256', process.env.LEMONSQUEEZY_WEBHOOK_SECRET)
      .update(rawBody)
      .digest('hex');

    if (computed !== signature) {
      return res.status(401).json({ error: 'Invalid signature' });
    }

    const event = JSON.parse(rawBody);

    switch (event.meta.event_name) {
      case 'subscription_created':
      case 'subscription_updated':
        const userId = event.meta.custom_data?.user_id;
        const status = event.data.attributes.status;
        const variantId = event.data.attributes.variant_id;

        console.log(`User ${userId} subscription status: ${status}, variant: ${variantId}`);

        // For this implementation, we'll store the subscription info
        // In a real app, you would update your database here
        // The frontend will check for payment success via URL parameters
        break;

      case 'subscription_cancelled':
        const cancelledUserId = event.meta.custom_data?.user_id;
        console.log(`User ${cancelledUserId} subscription cancelled`);
        break;

      case 'order_created':
        // One-time payment successful
        const orderUserId = event.meta.custom_data?.user_id;
        const orderStatus = event.data.attributes.status;
        console.log(`User ${orderUserId} order status: ${orderStatus}`);
        break;
    }

    res.status(200).json({ received: true });
  } catch (error) {
    console.error('Webhook Error:', error);
    res.status(500).json({ error: error.message });
  }
}

function getRawBody(req) {
  return new Promise((resolve, reject) => {
    let data = '';
    req.on('data', chunk => data += chunk);
    req.on('end', () => resolve(data));
    req.on('error', reject);
  });
}
