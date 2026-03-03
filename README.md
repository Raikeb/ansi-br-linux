# ANSI-BR (Linux)

Este repositório é o *port para Linux* do layout **ANSI-BR** (originalmente criado para Windows): um layout para **teclados ANSI (US)** com atalhos e caracteres úteis para **português brasileiro**, mantendo **dead keys** (acentos) do **US International**.

## Alterações (atalhos)

```
AltGr + ` = ≠
AltGr + 1 = ¹
AltGr + a = ª
AltGr + c = ç
AltGr + / = º
AltGr + , = ©
Shift + AltGr + , = ¢
Shift + AltGr + / = ¿
AltGr + Space = NBSP (caractere invisível, espaço não-quebrável)
```

O layout adiciona vários caracteres no AltGr conforme o arquivo KLC do projeto original (ex.: é/É no AltGr+E, ñ/Ñ no AltGr+N, etc.).

## Instalação (Ubuntu 24.04 / GNOME)

> **Recomendado:** instalação *system-wide* (o layout aparece no menu do GNOME).

1) Clone/baixe este repositório.

2) Execute o instalador:

```bash
sudo ./scripts/install-system.sh
```

3) **Faça logoff/login** (ou reinicie).

4) Vá em:

**Settings → Keyboard → Input Sources → “+”**  
Pesquise por **ANSI-BR** e selecione **Portuguese (Brazil, ANSI-BR)**.

### (Opcional) Compose para ficar 100% igual ao do projeto Windows

No layout do Windows, `dead_acute + c` vira **ç**. No Linux, isso depende das tabelas de Compose.

Se você quiser esse comportamento:

```bash
./scripts/install-compose.sh
```

Depois disso, faça logoff/login se necessário.

## Desinstalar

```bash
sudo ./scripts/uninstall-system.sh
```

E (se você instalou Compose):

```bash
./scripts/uninstall-compose.sh
```

## Observações importantes

- Atualizações do pacote `xkb-data`/`xkeyboard-config` podem sobrescrever `evdev.xml`/`evdev.lst`.  
  Se o layout “sumir” do menu, é só rodar o instalador novamente.
- Em sessões remotas (RDP / GNOME Remote Desktop), o mapeamento final também depende das configurações de teclado do cliente (Windows) e do servidor (Ubuntu).

## Estrutura

- `xkb/symbols/ansi-br` — arquivo de layout XKB
- `scripts/install-system.sh` — instala e registra o layout no sistema
- `scripts/uninstall-system.sh` — remove o layout do sistema
- `scripts/install-compose.sh` — opcional: sobrescreve `~/.XCompose` com as regras ANSI-BR
