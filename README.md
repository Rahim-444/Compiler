# 🛠️ Mini-Compilateur avec Flex et Bison  

## 📌 Présentation  
Ce projet est un **mini-compilateur** développé avec **Flex** (analyse lexicale) et **Bison** (analyse syntaxique).  
Il permet de traiter des expressions arithmétiques et des affectations de variables simples.  

## 🚀 Fonctionnalités  
- Prise en charge des **opérations arithmétiques** (`+`, `-`, `*`, `/`)  
- Gestion des **affectations** (`x = 5;`)  
- **Stockage des variables** et réutilisation dans les expressions  
- **Évaluation des expressions** (exemple : `y = x + 3;`)  
- **Traitement de plusieurs lignes** en continu  

## 🏗️ Installation et Compilation  

### **Prérequis**  
Avant de compiler, assurez-vous d'avoir installé **Flex** et **Bison**.  
Sous **Linux/Mac**, vous pouvez les installer avec :  

```sh
sudo apt install flex bison   # Debian/Ubuntu  
brew install flex bison       # macOS (Homebrew)  
