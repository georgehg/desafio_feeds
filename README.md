# Desafio Feeds

Projeto desenvolvido para o desafio do time de Feeds que consiste em baixar um arquivo XML, processá-lo e cadastrar os recursos de imóveis utilizando uma API REST.

### Prerequisitos

- **PERL5** - 
Este projeto foi desenvolvido utilizando a linguagem PERL. Portanto, é necessário ter uma versão do PERL (versão 12 ou superior)
instalada no ambiente onde será executado o programa.
Para instalar o PERL no MAC OSX pode-se seguir as instruções deste site: [Installing PERL on OSX](http://learn.perl.org/installing/osx.html). 

- **CPANM** - 
Algumas bibliotecas [CPAN](http://www.cpan.org/) foram utilizadas nesta aplicação. Portanto, é necessário estar instalado no sistema o instalador
de bibliotecas CPAN, o *cpanm*. Para instalar o cpanm execute o comando abaixo (pode ser necessário utilizar permissão de root):

    ```
    cpan App::cpanminus
    ou
    sudo cpan App::cpanminus
    ```
    Para mais informações veja [How to install CPAN modules](http://www.cpan.org/modules/INSTALL.html).

- **CARTON** - 
Este projeto utiliza a ferramenta [Carton](http://search.cpan.org/~miyagawa/Carton-v1.0.28/lib/Carton.pm) para realizar a gerência de
dependência das bibliotecas utilizados pelo programa. Para instalar o Carton execute o comando abaixo (pode ser necessário utilizar permissão de root):

   ```
   cpanm install Carton
   ou
   sudo cpanm install Carton
   ```

### Instalação

- Baixar o projeto desafio feeds:

    ```
    git clone https://github.com/georgehg/desafio_feeds
    ```
- Executar o carton para a instalação de todas as bibliotecas necessárias para o programa:
    ```
    carton install
    ```

  Após estes passos o programa está pronto para ser executado.

### Execução

  Para executar o programa basta executar o script *cadastro_Imoveis.pl*:

  ```
  ./cadastro_Imoveis.pl
  ```

### Configuração

  O script possui um arquivo de configuração localizado em ./cnf/config. Neste arquivo podem ser configurados o endereço do servidor para baixar o arquivo XML, o nome do arquivo XML a ser baixado e o endereço do servidor onde será executado o cadastro de recursos via API REST.

### Opções de execução

  O script pode receber alguns parâmetros de execução via argumentos de linha de comando. Para visualizar todos as opções possíveis executar o script com a opção --help:
  
  ```
  ./cadastro_Imoveis.pl --help
  ```

## Testes

  Para visualizar as mensagens sendo enviadas pelo script e respondidas pelo servidor de API REST, pode-se executar o script com o log em modo debug:
  
  ```
  ./cadastro_Imoveis.pl --debug
  ```
  
  Após realizar o download do arquivo XML com sucesso, o script salva localmente no diretório *resource* um arquivo xml de mesmo nome adicionando ao final do nome do arquivo a data e a hora do download. Exemplo:
  
  ```
  resource/imoveis.xml_20160614223625
  ```

  Após uma primeira execução do script é possível utilizar o mesmo XML para o teste do script, ou ainda outro arquivo XML qualquer presente na máquina. Para isso basta executar o script utilizando a opção --xmlFile:
  
  ```
  ./cadastro_Imoveis.pl --xmlFile=resource/imoveis.xml_20160614223625
  ```

## Authors

* **George Silva**
