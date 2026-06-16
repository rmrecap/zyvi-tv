const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const crypto = require('crypto');

const ENCRYPTION_KEY = process.env.STREAM_ENCRYPTION_KEY || 'ZyviTV-Default-Key-ChangeInProd!';

function encryptUrl(rawUrl) {
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv(
    'aes-256-cbc',
    crypto.createHash('sha256').update(ENCRYPTION_KEY).digest(),
    iv,
  );
  let encrypted = cipher.update(rawUrl, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return iv.toString('hex') + ':' + encrypted;
}

exports.getSecureStream = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to access stream URLs.',
    );
  }

  const channelId = data.channelId;
  if (!channelId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'channelId is required.',
    );
  }

  const channelDoc = await admin
    .firestore()
    .collection('zyvi_channels')
    .doc(channelId)
    .get();

  if (!channelDoc.exists) {
    throw new functions.https.HttpsError(
      'not-found',
      'Channel not found.',
    );
  }

  const channelData = channelDoc.data();
  const secureUrl = channelData?.secure_stream_url || channelData?.sources?.[0]?.url;

  if (!secureUrl) {
    throw new functions.https.HttpsError(
      'not-found',
      'No stream URL configured for this channel.',
    );
  }

  const encryptedUrl = encryptUrl(secureUrl);

  return {
    streamUrl: encryptedUrl,
    channelName: channelData?.name ?? '',
    resolutionQuality: channelData?.sources?.[0]?.resolutionQuality ?? 'Auto',
  };
});
