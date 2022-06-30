#!/usr/bin/env bash

# biblioteca pessoal compartilhada
source /usr/local/lib/mydump/common-properties.lib

# -------------------------------------------------------------------------------------------------------------------
# declaração de funções
# -------------------------------------------------------------------------------------------------------------------

set_max_steps() {
	value=${1}
	echo "MAX_STEPS:${value}" > ${fixed_tmp_files['max_stps_flg_file']}
}

clean_sleep_flag() {
	> ${fixed_tmp_files['sleep_flag_file']}
}

get_tmp_files() {
	tmp_arr[${index_tmp_files}]="${1}"
	let ++index_tmp_files
}

# -------------------------------------------------------------------------------------------------------------------
# declaração de variáveis
# -------------------------------------------------------------------------------------------------------------------

declare -A config=(\
	['database']="" \
	['database_local']="" \
	['user_db']="" \
	['passwd_db']="" \
	['domain']="" \
	['host']="" \
	['user_server']="" \
	['passwd_server']=""\
)
for config_var in ${!config[@]}; do
	config[${config_var}]=$(grep -Ei "^(${config_var}:)" ${fixed_tmp_files['coleta_info_file']} | cut -d ':' -f 2)
done
connection=${config['host']}
index_tmp_files=0
tmp_arr[${index_tmp_files}]=""

#####################################################################################################################
# 
# inicio do programa
#
#####################################################################################################################

echo "==================================================" >> ${file_log}
cat /usr/local/share/mydump/banner/banner.txt

# Printar manualmentea a infos escolhidas pelo usuário

# deixar o "set_max_steps" método automático para saber quantos steps tem baseado na quantidade de chamandas do "set_sleep_flag"
set_max_steps 25
clean_sleep_flag
loading-bar &

# exportando somente as tabelas que teram dados
# -------------------------------------------------------------------------------------------------------------------

tmp_file=$(mktemp /tmp/mydump_XXXXXXXXXXXXXXX.sql)
get_tmp_files ${tmp_file}

echo '>>> Exportando estrutura do banco !'
echo "mysqldump --no-data -h 127.0.0.1 -u ${config['user_db']} -p${config['passwd_db']} ${config['database']} > ${tmp_file}" > ${tmp_file}
set_sleep_flag true
if ! error_msg=$(sshpass -p ${config['passwd_server']} scp -o StrictHostKeyChecking=no ${tmp_file} ${config['user_server']}@${connection}:${tmp_file} 2>&1); then
	cat <<- EOF
		FATAL ERROR (ip): Não foi possível estabelecer a conexão!"
		STDERR: ${error_msg}
		Exitando para outro método... (código de erro 7)!
	EOF
	connection=${config['domain']}
	if ! error_msg=$(sshpass -p ${config['passwd_server']} scp -o StrictHostKeyChecking=no ${tmp_file} ${config['user_server']}@${connection}:${tmp_file} 2>&1); then
		cat <<- EOF
			FATAL ERROR (domain): Não foi possível estabelecer a conexão!"
			STDERR: ${error_msg}
			Saindo do programa em 15 segundos... (código de erro 7)!
		EOF
		rm ${tmp_file}
		sleep ${final_sleep_time}
		set_sleep_flag true
		exit 7
	fi
fi
set_sleep_flag true
sshpass -p ${config['passwd_server']} ssh ${config['user_server']}@${connection} "chmod +x ${tmp_file}; ${tmp_file}" 2>>${file_log}
set_sleep_flag true
sshpass -p ${config['passwd_server']} scp ${config['user_server']}@${connection}:${tmp_file} ${tmp_file}
set_sleep_flag true

no_tables=$(egrep -i 'create table' ${tmp_file} | egrep -i '(tbstoragelist)|(tbfilaitem)|(log)|.*(50001){1}.*v.*' | sed 's/\/\*!50001 //g' | cut -d ' ' -f '3' | sed 's/`//g' | tr '\n' ' ')
for table in ${no_tables}; do
	ignore_tables=$(echo "${ignore_tables} --ignore-table=${config['database']}.${table}")
done
set_sleep_flag true

echo '>>> Exportando somente as tabelas que conteram dados !'
echo "mysqldump ${ignore_tables# } -h 127.0.0.1 -u ${config['user_db']} -p${config['passwd_db']} ${config['database']} > ${tmp_file}" > ${tmp_file}
set_sleep_flag true
sshpass -p ${config['passwd_server']} scp ${tmp_file} ${config['user_server']}@${connection}:${tmp_file}
set_sleep_flag true
sshpass -p ${config['passwd_server']} ssh ${config['user_server']}@${connection} "chmod +x ${tmp_file}; ${tmp_file}" 2>>${file_log}
set_sleep_flag true
sshpass -p ${config['passwd_server']} scp ${config['user_server']}@${connection}:${tmp_file} ${tmp_file}
set_sleep_flag true

# exportando somente a estrutura das tabelas que não teram dados
# -------------------------------------------------------------------------------------------------------------------

ignore_tables=""
tmp_file_other=$(mktemp /tmp/mydump_XXXXXXXXXXXXXXX.sql)
get_tmp_files ${tmp_file_other}

echo '>>> Exportando estrutura do banco !'
echo "mysqldump --no-data -h 127.0.0.1 -u ${config['user_db']} -p${config['passwd_db']} ${config['database']} > ${tmp_file_other}" > ${tmp_file_other}
set_sleep_flag true
sshpass -p ${config['passwd_server']} scp ${tmp_file_other} ${config['user_server']}@${connection}:${tmp_file_other}
set_sleep_flag true
sshpass -p ${config['passwd_server']} ssh ${config['user_server']}@${connection} "chmod +x ${tmp_file_other}; ${tmp_file_other}" 2>>${file_log}
set_sleep_flag true
sshpass -p ${config['passwd_server']} scp ${config['user_server']}@${connection}:${tmp_file_other} ${tmp_file_other}
set_sleep_flag true

yes_tables=$(egrep -i 'create table' ${tmp_file_other} | egrep -iv '(tbstoragelist)|(tbfilaitem)|(log)' | sed 's/\/\*!50001 //g' | cut -d ' ' -f '3' | sed 's/`//g' | tr '\n' ' ')
for table in ${yes_tables}; do
	ignore_tables=$(echo "${ignore_tables} --ignore-table=${config['database']}.${table}")
done
set_sleep_flag true

echo '>>> Exportando somente a estrutura das tabelas que não conteram dados !'
echo "mysqldump --no-data ${ignore_tables# } -h 127.0.0.1 -u ${config['user_db']} -p${config['passwd_db']} ${config['database']} > ${tmp_file_other}" > ${tmp_file_other}
set_sleep_flag true
sshpass -p ${config['passwd_server']} scp ${tmp_file_other} ${config['user_server']}@${connection}:${tmp_file_other}
set_sleep_flag true
sshpass -p ${config['passwd_server']} ssh ${config['user_server']}@${connection} "chmod +x ${tmp_file_other}; ${tmp_file_other}" 2>>${file_log}
set_sleep_flag true
sshpass -p ${config['passwd_server']} scp ${config['user_server']}@${connection}:${tmp_file_other} ${tmp_file_other}
set_sleep_flag true

echo "" >> ${tmp_file}
cat ${tmp_file_other} >> ${tmp_file}
set_sleep_flag true

# importando banco remoto para local
# -------------------------------------------------------------------------------------------------------------------

echo '>>> Dropando e Criando o banco local !'
mysql -h 127.0.0.1 -u mkommerce -p12345678 --execute="DROP DATABASE ${tmp_name_db}" 2>>${file_log}
set_sleep_flag true
mysql -h 127.0.0.1 -u mkommerce -p12345678 --execute="CREATE DATABASE ${tmp_name_db}" 2>>${file_log}
set_sleep_flag true
echo '>>> Importando para o banco local !'
mysql -h 127.0.0.1 -u mkommerce -p12345678 ${tmp_name_db} < ${tmp_file} 2>>${file_log}
set_sleep_flag true

# views, triggers, procedures
# -------------------------------------------------------------------------------------------------------------------

tmp_file_view=$(mktemp /tmp/mydump_view_XXXXXXXXXXXXXXX.sql)
tmp_file_trigger=$(mktemp /tmp/mydump_trigger_XXXXXXXXXXXXXXX.sql)
tmp_file_procedure=$(mktemp /tmp/mydump_procedure_XXXXXXXXXXXXXXX.sql)
get_tmp_files ${tmp_file_view}
get_tmp_files ${tmp_file_trigger}
get_tmp_files ${tmp_file_procedure}

wget -qO - "https://${config['domain']}/ferramentas/join-create-views" > ${tmp_file_view}
wget -qO - "https://${config['domain']}/ferramentas/join-create-procedures" > ${tmp_file_procedure}
wget -qO - "https://${config['domain']}/ferramentas/join-create-triggers" > ${tmp_file_trigger}

for sql in /tmp/mydump_{view,trigger,procedure}_*.sql; do
	tmp_file_sql="$(basename ${sql%_*} | sed 's/^.*_//')"
	echo ">>> ${tmp_file_sql^} !"
	mysql -h 127.0.0.1 -u mkommerce -p12345678 ${tmp_name_db} < ${sql} 2>>${file_log}
	set_sleep_flag true
done

for file in ${tmp_arr[@]}; do
	rm ${file}
done
set_sleep_flag true

echo '>>> PRONTO !'

echo ' '

echo "Saindo em ${final_sleep_time} segundos..."

sleep ${final_sleep_time}
