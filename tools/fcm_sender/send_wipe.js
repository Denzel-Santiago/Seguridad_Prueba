const admin = require('firebase-admin');

/**
 * Procedimiento:
 * 1. Descarga tu archivo serviceAccountKey.json desde Firebase Console.
 * 2. Colócalo en esta carpeta (asegúrate de que no se suba a Git).
 * 3. Ejecuta:
 *    export GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"
 *    export FCM_TOKEN="token_del_dispositivo"
 *    node send_wipe.js
 */

const token = process.env.FCM_TOKEN;

if (!token) {
  console.error('Error: La variable de entorno FCM_TOKEN no está definida.');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.applicationDefault()
});

const message = {
  data: {
    action: 'WIPE_SECURE_DATA'
  },
  token: token,
  android: {
    priority: 'high'
  }
};

admin.messaging().send(message)
  .then((response) => {
    console.log('Mensaje enviado exitosamente:', response);
  })
  .catch((error) => {
    console.error('Error enviando mensaje:', error);
  });
