# How to use

- Just clone this repo in your .github folder of your project.
- Ingore this repo in your own repo.


# How to add only certain files/folders

## 1. Crea la carpeta .github si no existe y entra
mkdir -p .github && cd .github

## 2. Inicializa un repositorio vacío (no hagas clone directo aquí)
- git init
- git remote add origin https://github.com/geekscalada/myIAFlow.git

## 3. Activa el modo Sparse-Checkout (el filtro)
git config core.sparseCheckout true

## 4. Define qué archivos o carpetas quieres "traer"
## Por ejemplo: un agente específico y la carpeta de skills
echo "mi-agente-web.md" >> .git/info/sparse-checkout
echo "skills/python-pro/" >> .git/info/sparse-checkout

## 5. Descarga solo esos archivos
git pull origin main
