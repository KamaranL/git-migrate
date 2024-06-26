# git-migrate

## Configuration

1. Set up the following directory structure:

   ```text
   ./
   |-- commands/
   |-- conf/
       |-- main.conf
   |-- hooks/
   ```

2. Consolidate your global and system git config files into ./conf/main.conf.

## Usage

1. Run the following command from the top level (root) of the directory structure shown in the previous section.
   1. MacOS/Linux

       ```bash
       bash <(curl -sL 'https://raw.githubusercontent.com/KamaranL/git-migrate/main/install.sh')

       ```

   2. Windows

       ```powershell
       iwr 'https://raw.githubusercontent.com/KamaranL/git-migrate/main/Install.ps1').Content
       ```
