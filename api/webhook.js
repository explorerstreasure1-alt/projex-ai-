// Lemonsqueezy Webhook Handler
import crypto from 'crypto';

export default async function handler(req, res) {
  // Add CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, x-signature');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const rawBody = req.body;
    const signature = req.headers['x-signature'];

    if (!signature) {
      return res.status(400).json({ error: 'Missing signature header' });
    }

    // Verify webhook signature
    const webhookSecret = process.env.LEMONSQUEEZY_WEBHOOK_SECRET;
    if (!webhookSecret) {
      console.error('LEMONSQUEEZY_WEBHOOK_SECRET not configured');
      return res.status(500).json({ error: 'Server configuration error' });
    }

    const computed = crypto
      .createHmac('sha256', webhookSecret)
      .update(JSON.stringify(rawBody))
      .digest('hex');

    if (computed !== signature) {
      return res.status(401).json({ error: 'Invalid signature' });
    }

    const event = rawBody;

    switch (event.meta?.event_name) {
      case 'subscription_created':
      case 'subscription_updated':
        const userId = event.meta?.custom_data?.user_id;
        const status = event.data?.attributes?.status;
        const variantId = event.data?.attributes?.variant_id;

        console.log(`User ${userId} subscription status: ${status}, variant: ${variantId}`);
        break;

      case 'subscription_cancelled':
        const cancelledUserId = event.meta?.custom_data?.user_id;
        console.log(`User ${cancelledUserId} subscription cancelled`);
        break;

      case 'order_created':
        const orderUserId = event.meta?.custom_data?.user_id;
        const orderStatus = event.data?.attributes?.status;
        console.log(`User ${orderUserId} order status: ${orderStatus}`);
        break;
    }

    res.status(200).json({ received: true });
  } catch (error) {
    console.error('Webhook Error:', error);
    res.status(500).json({ error: error.message });
  }
}
