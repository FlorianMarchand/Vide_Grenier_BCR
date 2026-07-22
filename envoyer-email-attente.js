// ============================================
// EMAIL AUTOMATIQUE — étape "place bloquée"
// Remplace l'ancienne étape 2 manuelle (le CFR répondait par email
// en confirmant le blocage). Ici c'est envoyé instantanément.
// ============================================

const { envoyerEmail } = require('./lib/email');

exports.handler = async (event) => {
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Méthode non autorisée' };
  }

  let payload;
  try {
    payload = JSON.parse(event.body);
  } catch {
    return { statusCode: 400, body: 'Corps de requête invalide' };
  }

  const { codes, nom, email, expiration, prix } = payload;
  if (!codes || !codes.length || !email) {
    return { statusCode: 400, body: 'Champs manquants' };
  }

  const dateLimite = new Date(expiration).toLocaleString('fr-FR', {
    dateStyle: 'long',
    timeStyle: 'short'
  });

  const html = `
    <p>Bonjour ${nom},</p>
    <p>Votre demande de réservation pour le vide-greniers du Comité Fête des Roses
    (Brie-Comte-Robert) a bien été prise en compte pour ${codes.length > 1 ? 'les emplacements' : "l'emplacement"} :</p>
    <p style="font-size:1.1em; font-weight:bold;">${codes.join(', ')}</p>
    <p>Montant à régler : <strong>${prix} €</strong></p>
    <p><strong>Cette réservation est provisoire.</strong> Merci de finaliser le paiement
    avant le <strong>${dateLimite}</strong>. Passé ce délai, ${codes.length > 1 ? 'les emplacements redeviendront disponibles' : "l'emplacement redeviendra disponible"}.</p>
    <p>Vous avez été redirigé vers HelloAsso pour procéder au paiement sécurisé.</p>
    <p>À bientôt,<br>Le Comité Fête des Roses</p>
  `;

  const envoye = await envoyerEmail({
    destinataire: email,
    sujet: `Vide-greniers CFR — réservation en attente de paiement (${codes.join(', ')})`,
    html
  });

  return {
    statusCode: envoye ? 200 : 500,
    body: envoye ? 'Email envoyé' : "Échec de l'envoi de l'email"
  };
};
