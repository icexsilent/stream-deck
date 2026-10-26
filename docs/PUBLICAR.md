# Publicar o app

Estas etapas precisam de você: envolvem pagamento, documentos e login nas lojas.

## Android: Google Play (US$ 25, uma vez só)

1. Crie a conta em https://play.google.com/console (cerca de 30 min, mais 1 a 3 dias de verificação de identidade).
2. Gere a chave de assinatura, que é sua e nunca vai para o git:
   ```powershell
   keytool -genkey -v -keystore $HOME\stream-deck-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
3. Crie `app/android/key.properties` (já está fora do git) com:
   ```
   storePassword=SUA_SENHA
   keyPassword=SUA_SENHA
   keyAlias=upload
   storeFile=C:\\Users\\vinic\\stream-deck-upload.jks
   ```
4. Peça para eu ligar a assinatura no `build.gradle.kts`. Depois rode `flutter build appbundle` e envie o `.aab` no Play Console.
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
