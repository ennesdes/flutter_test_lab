# Flutter Test Lab

Um projeto Flutter criado para testar e validar pacotes e funcionalidades antes de implementá-los em projetos principais.

## 🎯 Objetivo

Este projeto serve como um laboratório de testes para:
- Validar pacotes Flutter antes de usar em projetos de produção
- Testar novas funcionalidades de forma isolada
- Experimentar diferentes abordagens de arquitetura
- Aprender e praticar novos recursos do Flutter

## 🏗️ Arquitetura

O projeto segue uma arquitetura limpa e organizada:

```
lib/
├── app/
│   └── app.dart                 # Configuração principal da aplicação
├── core/
│   └── theme/
│       └── app_theme.dart       # Temas da aplicação
├── features/
│   └── home/
│       └── presentation/
│           └── pages/
│               └── home_page.dart # Página inicial
├── shared/                      # Componentes compartilhados
└── main.dart                    # Ponto de entrada da aplicação
```

## 🚀 Funcionalidades

### Implementadas
- ✅ Interface inicial com grid de funcionalidades
- ✅ Sistema de temas (claro/escuro)
- ✅ Arquitetura base limpa

### Planejadas
- 🎤 Gravação de áudio em chat
- 📱 Outras funcionalidades a serem definidas

## 📱 Plataformas Suportadas

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## 🛠️ Como Usar

1. Clone o repositório
2. Execute `flutter pub get`
3. Execute `flutter run` para testar

## 📦 Dependências

O projeto usa apenas dependências nativas do Flutter por padrão. Pacotes específicos serão adicionados conforme necessário para cada funcionalidade testada.

## 🎨 Design

- Material Design 3
- Suporte a tema claro e escuro
- Interface responsiva
- Componentes reutilizáveis

## 📝 Licença

Este projeto é de uso pessoal para testes e desenvolvimento.
