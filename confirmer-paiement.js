// ============================================
// WEBHOOK DE CONFIRMATION DE PAIEMENT
// TODO : à finaliser une fois l'app tierce de paiement choisie.
//
// Ce fichier reçoit la notification de paiement et passe la place
// de "en_attente" à "reserve". Il ne fait rien d'autre.
// ============================================

const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY // clé service_role, jamais exposée côté client
);

exports.handler = async (event) => {
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Méthode non autorisée' };
  }

  // TODO — sécuriser l'appel : vérifier une signature ou un secret partagé
  // fourni par l'app tierce, pour être sûr que la requête vient bien d'elle.
  // Exemple générique (à adapter au mécanisme réel de l'app choisie) :
  //
  // const secret = event.headers['x-webhook-secret'];
  // if (secret !== process.env.WEBHOOK_SECRET) {
  //   return { statusCode: 401, body: 'Non autorisé' };
  // }

  let payload;
  try {
    payload = JSON.parse(event.body);
  } catch {
    return { statusCode: 400, body: 'Corps de requête invalide' };
  }

  // TODO — adapter ces noms de champs au format exact envoyé par l'app tierce
  const reference_paiement = payload.reference_paiement || payload.reference || null;
  const paiement_confirme = payload.statut === 'paye' || payload.status === 'paid';

  if (!reference_paiement) {
    return { statusCode: 400, body: 'Référence de paiement manquante' };
  }

  if (!paiement_confirme) {
    return { statusCode: 200, body: 'Ignoré (paiement non confirmé)' };
  }

  const { data, error } = await supabase
    .from('emplacements')
    .update({ statut: 'reserve', expiration: null })
    .eq('reference_paiement', reference_paiement)
    .eq('statut', 'en_attente')
    .select();

  if (error || !data || data.length === 0) {
    return { statusCode: 404, body: 'Réservation introuvable ou déjà traitée' };
  }

  return { statusCode: 200, body: `Place ${data[0].code} confirmée` };
};
