#!/bin/bash

# script pra rodar novamente o server automático em caso de crash
echo "Iniciando o programa"

cd /var/server
mkdir -p logs

# config mysql
usersql="user"
servername="database"
sqlpassword="senhA"

date=`date "+%d-%m-%y-%H-%M-%S"`
filename="${servername}-${date}"
databasefile="${filename}.sql"

#configs necessárias para o Anti-rollback
ulimit -c unlimited
set -o pipefail

while true 		#repetir pra sempre
do
 	#roda o server e guarda o output ou qualquer erro no logs
	#PS: o arquivo gdb_config deve estar na pasta do tfs
	gdb --batch -return-child-result --command=gdb_config --args ./tfs 2>&1 | awk '{ print strftime("%F %T - "), $0; fflush(); }' | tee "logs/$(date +"%F %H-%M-%S.log")"
	mysqldump -u$usersql -p$sqlpassword --add-drop-table --add-locks --allow-keywords --extended-insert --quick --compress $servername > /var/server/database/$databasefile
	gzip /var/server/database/$databasefile-f
	 
	if [ $? -eq 0 ]; then
		echo "Exit code 0, aguardando 10 minutos..."	 #pra ser usado no backup do banco de dados, precisa ser 10 min ou mais pra baixar a database
		sleep 600	#10 minutos
	else
		echo "Crash!! Reiniciando o servidor em 5 segundos (O arquivo de log está guardado na pasta logs)"
		echo "Se quiser encerrar o servidor, pressione CTRL + C..."
		sleep 5
	fi
done;
