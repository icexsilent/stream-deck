# Publicar o app

Estas etapas precisam de você: envolvem pagamento, documentos e login nas lojas.

## Android: Google Play (US$ 25, uma vez só)

1. Crie a conta em https://play.google.com/console (cerca de 30 min, mais 1 a 3 dias de verificação de identidade).
2. A chave de assinatura já existe em `C:\Users\vinic\.stream-deck\upload.jks`, com a senha em `key.properties` na mesma pasta. **Faça backup dessa pasta**: sem ela, quem já instalou o app não consegue atualizar.
3. `app/android/key.properties` (fora do git) aponta para essa chave, e o `build.gradle.kts` já assina as versões com ela.
4. Rode `flutter build appbundle` e envie o `.aab` no Play Console.
5. Contas novas precisam de um **teste fechado com 12 testadores por 14 dias** antes de publicar para todo mundo.

Até lá, o APK de `app/build/app/outputs/flutter-apk/` pode ser instalado direto no celular, sem loja.

## iOS: App Store (US$ 99 por ano)

1. Assine o Apple Developer Program em https://developer.apple.com/programs (1 a 2 dias de aprovação).
2. No App Store Connect, crie o app com o bundle ID `com.icexsilent.streamDeck`.
3. Crie uma chave de API em App Store Connect > Usuários e acesso > Integrações (função **App Manager**).
4. No https://codemagic.io, entre com o GitHub, adicione o repo `stream-deck`, cadastre a chave em Teams > Integrations com o nome `codemagic` e rode o workflow **iOS TestFlight**.
5. Instale o TestFlight no iPhone e teste. Quando estiver tudo certo, envie para revisão no App Store Connect.

No iOS, o app pede permissão de **Rede local**. Sem ela, não encontra o PC.

## Antes de enviar para as lojas

- Ícone do app: troque os arquivos em `app/android/app/src/main/res/mipmap-*` e `app/ios/Runner/Assets.xcassets`.
- Política de privacidade: as duas lojas exigem uma URL. O app não coleta dados; tudo fica na sua rede local.
