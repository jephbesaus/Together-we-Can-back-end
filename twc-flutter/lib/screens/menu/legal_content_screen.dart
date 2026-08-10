import 'package:flutter/material.dart';

class LegalContentScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalContentScreen({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(title), backgroundColor: theme.scaffoldBackgroundColor),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(content, style: const TextStyle(fontSize: 14, height: 1.6)),
      ),
    );
  }

  static const String terms = '''
Conditions d'utilisation - Together We Can

1. Acceptation des conditions
En utilisant Together We Can, vous acceptez les présentes conditions d'utilisation.

2. Compte utilisateur
Vous êtes responsable de la confidentialité de vos identifiants de connexion. Toute activité effectuée depuis votre compte est de votre responsabilité.

3. Contenu publié
Vous êtes seul responsable des publications, photos, vidéos et messages que vous partagez. Tout contenu illégal, haineux ou inapproprié sera supprimé et peut entraîner la suspension de votre compte.

4. Marketplace
Together We Can met en relation acheteurs et vendeurs mais n'est pas partie prenante des transactions. Les litiges doivent être signalés via le support.

5. Portefeuille et paiements
Les dépôts et retraits sont traités via des partenaires de paiement mobile money tiers. Together We Can n'est pas responsable des délais de traitement de ces partenaires.

6. Clic-Boost
Les services de promotion sur réseaux sociaux sont fournis par un partenaire externe. Les résultats peuvent varier selon les plateformes.

7. Modération
L'équipe administrative se réserve le droit de suspendre ou supprimer tout compte ne respectant pas ces conditions.

8. Modification des conditions
Ces conditions peuvent être mises à jour. Les utilisateurs seront informés des changements majeurs via une actualité dans l'application.
''';

  static const String privacy = '''
Politique de confidentialité - Together We Can

1. Données collectées
Nous collectons : nom, email, téléphone, photo de profil, publications, et les données nécessaires au fonctionnement du portefeuille et de la marketplace.

2. Utilisation des données
Vos données servent uniquement à faire fonctionner l'application : authentification, affichage de votre profil, traitement des paiements, notifications.

3. Partage des données
Nous ne vendons jamais vos données. Elles sont partagées uniquement avec nos partenaires techniques nécessaires (paiement mobile money, notifications push) dans la stricte mesure du nécessaire.

4. Sécurité
Votre mot de passe est chiffré et jamais stocké en clair. Les communications avec nos serveurs sont sécurisées.

5. Vos droits
Vous pouvez à tout moment modifier vos informations depuis Paramètres > Modifier le profil, ou demander la suppression de votre compte en contactant le support.

6. Conservation des données
Vos données sont conservées tant que votre compte est actif. En cas de suppression de compte, vos données personnelles sont effacées sous 30 jours.

7. Contact
Pour toute question relative à vos données, contactez jephbesaus07@gmail.com.
''';
}
