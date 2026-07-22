// ============================================
// CRÉATION DU PAIEMENT HELLOASSO
// Appelée par le site juste après avoir bloqué les places (statut = en_attente).
// Crée une "intention de paiement" HelloAsso et renvoie l'URL vers laquelle
// rediriger le client pour payer.
// ============================================

const PRIX_PAR_EMPLACEMENT_CENTIMES = 1300; // 13 € / emplacement de 2ml

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

  const { codes, reference, nom, email } = payload;
  if (!codes || !codes.length || !reference || !nom || !email) {
    return { statusCode: 400, body: 'Champs manquants (codes, reference, nom, email)' };
  }

  const totalAmount = PRIX_PAR_EMPLACEMENT_CENTIMES * codes.length;
  const [prenom, ...resteNom] = nom.trim().split(' ');
  const nomFamille = resteNom.join(' ') || prenom;

  try {
    const token = await obtenirJetonHelloAsso();

    const reponse = await fetch(
      `https://api.helloasso.com/v5/organizations/${process.env.HELLOASSO_ORG_SLUG}/checkout-intents`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
          totalAmount,
          initialAmount: totalAmount,
          itemName: `Vide-greniers P1 — emplacement(s) ${codes.join(', ')}`,
          containsDonation: false,
          backUrl: `${process.env.SITE_URL}/?paiement=annule`,
          errorUrl: `${process.env.SITE_URL}/?paiement=erreur`,
          returnUrl: `${process.env.SITE_URL}/?paiement=retour&ref=${reference}`,
          payer: {
            firstName: prenom,
            lastName: nomFamille,
            email: email
          },
          metadata: {
            payment_ref: reference,
            codes: codes.join(',')
          }
        })
      }
    );

    const data = await reponse.json();

    if (!reponse.ok) {
      console.error('Erreur HelloAsso:', data);
      return { statusCode: 502, body: 'Erreur lors de la création du paiement HelloAsso' };
    }

    return {
      statusCode: 200,
      body: JSON.stringify({ redirectUrl: data.redirectUrl })
    };

  } catch (err) {
    console.error(err);
    return { statusCode: 500, body: 'Erreur serveur' };
  }
};

async function obtenirJetonHelloAsso() {
  const reponse = await fetch('https://api.helloasso.com/oauth2/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'client_credentials',
      client_id: process.env.HELLOASSO_CLIENT_ID,
      client_secret: process.env.HELLOASSO_CLIENT_SECRET
    })
  });
  const data = await reponse.json();
  if (!reponse.ok) throw new Error('Impossible d\'obtenir le jeton HelloAsso: ' + JSON.stringify(data));
  return data.access_token;
}
