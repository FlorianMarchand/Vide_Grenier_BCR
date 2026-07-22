// ============================================
// ENVOI D'EMAIL — via l'API Resend (https://resend.com)
// Nécessite la variable d'environnement RESEND_API_KEY
// et RESEND_FROM (adresse d'expédition validée sur Resend).
// ============================================

async function envoyerEmail({ destinataire, sujet, html }) {
  const reponse = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.RESEND_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      from: process.env.RESEND_FROM, // ex: "CFR Vide-greniers <reservation@votredomaine.fr>"
      to: [destinataire],
      subject: sujet,
      html
    })
  });

  if (!reponse.ok) {
    const erreur = await reponse.text();
    console.error('Erreur envoi email:', erreur);
  }
  return reponse.ok;
}

module.exports = { envoyerEmail };
