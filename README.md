# ChrisH4xAppStoreTroller 🎭

> Troller le détecteur de version iOS dans l'App Store. Par **ChrisH4x**.

---

## ✨ Fonctionnalités

| Feature | Détail |
|---|---|
| 🎭 Spoof iOS version | Retourne la version de ton choix à l'App Store |
| 👆 Long-press 3s | Sur **Obtenir / Get / Installer / Avoir / Acheter** → popup version |
| ⚠️ Incompatibilité réelle | Si app nécessite iOS 17 et tu mets 7 → vrai message d'incompatibilité |
| 🚫 Limite max iOS 100 | 101+ est bloqué avec un message d'erreur |
| 📋 Historique | Les 50 dernières apps installées avec la version spoofée utilisée |
| ⚙️ Réglages | Panel dans l'app Réglages pour activer/désactiver + voir l'historique |
| 🗑️ Effacer historique | Bouton pour vider l'historique dans les préférences |

---

## 📱 Compatibilité

- **Jailbreaks** : Unc0ver, Checkra1n, Taurine, Palera1n, Dopamine, Freya, et tous les autres
- **Mode** : Rootful **&** Rootless
- **Architectures** : `arm` + `arm64`
- **iOS** : 5.0 → 18.x
- **Cydia / Sileo / Zebra** : ✅ Visible + installable

---

## 🚀 Comment utiliser

1. Installe via Cydia/Sileo/Zebra
2. Va dans **Réglages → ChrisH4xAppStoreTroller** et active le tweak
3. Ouvre l'**App Store**
4. Navigue vers une app
5. **Appuie 3 secondes** sur le bouton **Obtenir / Get / Installer / Avoir**
6. Une popup apparaît → tape ta version iOS souhaitée (ex : `99`)
7. Appuie sur ✅ **Appliquer**
8. Profite !

> **Fun fact :** Si une app nécessite iOS 17 et que tu tapes `7` par erreur, le message d'incompatibilité normal apparaît — exactement comme si tu avais vraiment iOS 7 !

---

## 🔢 Règles de version

```
Minimum : iOS 1
Maximum : iOS 100  (101+ est bloqué 🚫)
Défaut  : iOS 99
```

---

## 🔨 Build avec Theos

### Prérequis

- [Theos](https://theos.dev) installé
- SDK iOS (5.0 → 18.x)

### Rootful

```bash
cd ChrisH4xAppStoreTroller
make package
```

### Rootless (Palera1n, Dopamine, Freya…)

```bash
cd ChrisH4xAppStoreTroller
THEOS_PACKAGE_SCHEME=rootless make package
```

Le `.deb` généré se trouve dans `packages/`.

---

## 📂 Structure du projet

```
ChrisH4xAppStoreTroller/
├── Makefile                          # Build config (rootful + rootless)
├── control                           # Infos paquet Cydia
├── ChrisH4xAppStoreTroller.plist     # MobileSubstrate filter
├── Tweak.x                           # Code principal (Logos/ObjC)
├── Prefs/
│   ├── Makefile
│   ├── CHXPreferencesController.h
│   ├── CHXPreferencesController.m    # Panel Réglages
│   └── Resources/
│       └── Info.plist
├── layout/
│   ├── DEBIAN/
│   │   ├── control
│   │   ├── postinst                  # Kill daemons après install
│   │   └── prerm                    # Nettoyage avant désinstall
│   └── Library/PreferenceLoader/Preferences/
│       └── ChrisH4xAppStoreTroller.plist
└── Resources/
    └── depiction.json                # Page Cydia/Sileo
```

---

## ⚠️ Disclaimer

Ce tweak est à des fins éducatives. Utilise-le de façon responsable.

---

*Made with 🔥 by ChrisH4x*
