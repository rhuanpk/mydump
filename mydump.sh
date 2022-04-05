#!/usr/bin/env bash

############################################################################
#
# ~~~ DEPRECEATED ~~~
#
# 1 - caminho absoluto do arquivo
#  1.1 - nome do arquivo tem que ser o usuário do banco
#  1.2 - conteúdo do arquivo tem que ter a senha do banco
# 2 - nome do banco de dados que será feito a exportação
# 3 - nome do usario do servior
# 4 - ip do sevidor que tenha o sgbd
# 5 - dominio do clinete
# 6 - senha do servidor
#
# exemplo: ~/script/mydump.sh '/tmp/tmp/mkommerce.tmp' '127.0.0.1' 'testando' 'b2byexxc' 'b2b.yexx.com.br' 'xxxxxxxxxx'
#
############################################################################

# PENDENCIAS:
# - fazer com que mesmo um arquivo já exista, criar outro personalizado; ()
# - fazer com que seja possível excluir arquivos de configuração; (-)
# - poder editar informações de um arquivo já existente; ()
# - poder excolher vizualmente qual arquivo quer usar; ()
# - fazer uma barra de progresso; ()
# - suprimir erros esperados; ()
# - cirar os arquivos de log e parâmetros (referentes); ()
# - testar conexão ssh via ip, caso não retorne positivo, tente via dominio, caso falhe, exite, mostrando para o usuário ()

# ------------------------------------------------------------------------------------------------------------------
# declaração de funções (coleta)
# -------------------------------------------------------------------------------------------------------------------

coleta_info() {

	info1() {
		read -p "${config_name['user_db']}: " config['user_db']
	}

	info2() {
		read -p "${config_name['passwd_db']}: " config['passwd_db']
	}

	info3() {
		read -p "${config_name['domain']}: " config['domain']
	}
	
	info4() {
		read -p "${config_name['host']}: " config['host']
	}
	
	info5() {
		read -p "${config_name['user_server']}: " config['user_server']
	}
	
	info6() {
		read -p "${config_name['passwd_server']}: " config['passwd_server']
	}

	info7() {
		read -p "Informe o nome do banco local a ser criado (enter para default: ${config['database']}): " config['database_local']
		if [ -z ${config['database_local']} ]; then
			tmp_name_db=${config['database']}
			config['database_local']=${tmp_name_db}
		else
			tmp_name_db=${config['database_local']}
		fi
	}

	info8() {
		read -s -p "${config_name['passwd_sudo']}: " passwd_sudo
	}
	
	
	info0() {
		for i in $(seq 8); do
			info${i}
		done	
	}
	
	info${1}
}

other_file_config() {
	cont=$(find ${mydump_path} -name "*${config['database']}*" | wc -l)
	if [ ${cont} -gt 1 ]; then
		path_completo="${mydump_path}/${config['database']}__${cont}.conf"
		touch ${path_completo}
		menu_coleta_info
	else
		old_file="${mydump_path}/${config['database']}__0.conf"
		mv ${path_completo} ${old_file}
		# echo '0' >> ${old_file}
		path_completo="${mydump_path}/${config['database']}__1.conf"
		touch ${path_completo}
		menu_coleta_info
	fi
}

menu_coleta_info() {
	while [ ${flag} -eq 0 ]; do
		coleta_info 0
		echo -ne "\n--> As informações estão corretas !? [Y/n] "; read answer
		if [ "${answer,,}" != "n" ]; then
			flag=1
		else
			while [ ${flag} -eq 0 ]; do
				cat <<- EOF
					Escolha o dado a ser alterado...
					1. ${config_name['user_db']}						
					2. ${config_name['passwd_db']}
					3. ${config_name['domain']}
					4. ${config_name['host']}
					5. ${config_name['user_server']}
					6. ${config_name['passwd_server']}
					7. ${config_name['database_local']}
					8. ${config_name['passwd_sudo']}
					0. TODAS AS INFORMAÇÕES
				EOF
				read -p "Escolha: " answer
				case ${answer} in
					[0-8]) coleta_info ${answer} ;;
					*) read -p "Opção inválida! <press enter> " readkey ;;
				esac
				cat <<- EOF
					1. Editar novamente
					0. Salvar e sair
				EOF
				read -p "Escolha: " answer
				[ ${answer} -eq 0 ] && flag=1
			done
		fi
	done
	for index in ${ordenacao}; do
		if [ "${index}" = "database" ]; then
			echo "${config["${index}"]}" | tr ' ' '\n' > ${path_completo}
		else
			echo "${config["${index}"]}" | tr ' ' '\n' >> ${path_completo}				
		fi
	done
	read -p "Realizar a exportação? [Y/n] " answer
	if [ "${answer,,}" = "n" ]; then
		exit 0
	fi
}

load_file() {
	tmp_file_path=${1}
	for index in ${ordenacao}; do
		config["${index}"]=$(sed -n ${cont}p ${tmp_file_path})
	done
}

# ------------------------------------------------------------------------------------------------------------------
# declaração de variáveis (coleta)
# -------------------------------------------------------------------------------------------------------------------

flag=0

declare -A config

declare -A config_name=( \
	['database']="Nome do banco........." \
	['user_db']="Usuário do banco......" \
	['passwd_db']="Senha do banco........" \
	['domain']="Domínio do cliente...." \
	['host']="IP do servidor........" \
	['user_server']="Usuário do servidor..." \
	['passwd_server']="Senha do servidor....." \
	['database_local']="Nome do banco local..." \
	['passwd_sudo']="Senha do computador..." \
)

mydump_path="/home/${USER}/.mydump"; [ ! -e ${mydump_path} ] && mkdir -v ${mydump_path}

ordenacao="database database_local user_db passwd_db domain host user_server passwd_server"

# ------------------------------------------------------------------------------------------------------------------
# inicio do programa (coleta)
# -------------------------------------------------------------------------------------------------------------------

read -p "Entre com o nome do banco a ser exportado: " config['database']
config_file="${config['database']}.conf"
path_completo="${mydump_path}/${config_file}"
config_files_all="$(find ${mydump_path} -name "*${config['database']}*")"

if [ -z "${config_files_all}" ]; then
	read -p "Não encontrado nenhum arquivo de configuração... Deseja cria-lo? [Y/n] " answer
	if [ "${answer,,}" = "n" ]; then
		echo "Não configurado um novo banco! (exited 7)"
		exit 7
	else
		echo "Iniciando criação do arquivo de configuação..."
		touch ${path_completo}
		menu_coleta_info
	fi
else
	while [ ${flag} -eq 0 ]; do
		echo -e "--> Arquivos de configuração já existentes <--"
		for tmp_index in $(tr '\n' ' ' <<< ${config_files_all}); do
			cont=1
			for index in ${ordenacao}; do
				if [ "${index}" = "database" ]; then
					echo "--------------------------------------------------"
					echo "*** cod [${cont}]: ${config['database']}.conf ***"
					echo -e "${config_name[${index}]}: $(sed -n ${cont}p ${tmp_index})"
				else
					echo -e "${config_name[${index}]}: $(sed -n ${cont}p ${tmp_index})"
				fi
				let ++cont
			done
			echo "--------------------------------------------------"
		done
		cat <<- EOF
			1. Realizar a exportação?
			2. Criar outro arquivo de configuração com banco local diferente?
			3. Excluir o arquivo?
			0. Sair
		EOF
		read -p 'Escolha: ' answer
		case ${answer} in
			1) echo "Realizando exportação..."; read -p "Escolha o código do arquivo: " numero; load_file $(sed -n "${numero}p" <<< ${config_files_all}); flag=1 ;;
			2) other_file_config ;;
			3) echo "Realizando exclusao..."; read -p "Escolha o código do arquivo: " numero; rm $(sed -n "${numero}p" <<< ${config_files_all}); exit 0 ;;
			0) exit 0 ;;
			*) read -p "Opção inválida! <press enter> " readkey ;;
		esac
	done
fi

# ------------------------------------------------------------------------------------------------------------------
# declaração de funções - principal
# -------------------------------------------------------------------------------------------------------------------

get_tmp_files() {
	tmp_arr[${index}]="${1}"
	let ++index
}

# ------------------------------------------------------------------------------------------------------------------
# declaração de variáveis - principal
# -------------------------------------------------------------------------------------------------------------------

index=0

# ------------------------------------------------------------------------------------------------------------------
# inicio do programa - principal
# -------------------------------------------------------------------------------------------------------------------

# exit 7

# ------------------------------------------------------------------------------------------------------------------
# setando titmeout do ssh
# -------------------------------------------------------------------------------------------------------------------

tmp_line=$(cat -n '/etc/ssh/ssh_config' | egrep '.*(#)+.*(ConnectTimeout)+.*' | cut -c 5-7 | sed 's/\t$//')
if [ ! -z ${tmp_line} ]; then
	echo -e "${passwd_sudo}\n" | sudo -S sed -i "${tmp_line}s/^#/ /" /etc/ssh/ssh_config && echo -e "${passwd_sudo}\n" | sudo -S sed -i "${tmp_line}s/0/15/" /etc/ssh/ssh_config
fi

# ------------------------------------------------------------------------------------------------------------------
# exportando somente as tabelas que teram dados
# -------------------------------------------------------------------------------------------------------------------

tmp_file=$(mktemp /tmp/XXXXX.sql)
get_tmp_files ${tmp_file}

echo "mysqldump --no-data -h 127.0.0.1 -u ${config['user_db']} -p${config['passwd_db']} ${config['database']} > ${tmp_file}" > ${tmp_file}
if ! error_msg=$(sshpass -p ${config['passwd_server']} scp -o StrictHostKeyChecking=no ${tmp_file} ${config['user_server']}@${config['host']}:${tmp_file} 2>&1); then
	cat <<- EOF
		FATAL ERROR: Não foi possível estabelecer a conexão!"
		STDERR: ${error_msg}
		Exitando do programa (exited 7)
	EOF
	rm ${tmp_file}
	exit 7
fi
time sshpass -p ${config['passwd_server']} ssh ${config['user_server']}@${config['host']} "chmod +x ${tmp_file}; ${tmp_file}"

sshpass -p ${config['passwd_server']} scp ${config['user_server']}@${config['host']}:${tmp_file} ${tmp_file}

no_tables=$(egrep -i 'create table' ${tmp_file} | egrep -i '(tbstoragelist)|(tbfilaitem)|(log)|.*(50001){1}.*v.*' | sed 's/\/\*!50001 //g' | cut -d ' ' -f '3' | sed 's/`//g' | tr '\n' ' ')
for table in ${no_tables}; do
	ignore_tables=$(echo "${ignore_tables} --ignore-table=${config['database']}.${table}")
done


echo "mysqldump ${ignore_tables# } -h 127.0.0.1 -u ${config['user_db']} -p${config['passwd_db']} ${config['database']} > ${tmp_file}" > ${tmp_file}
sshpass -p ${config['passwd_server']} scp ${tmp_file} ${config['user_server']}@${config['host']}:${tmp_file}
time sshpass -p ${config['passwd_server']} ssh ${config['user_server']}@${config['host']} "chmod +x ${tmp_file}; ${tmp_file}"

sshpass -p ${config['passwd_server']} scp ${config['user_server']}@${config['host']}:${tmp_file} ${tmp_file}

# ------------------------------------------------------------------------------------------------------------------
# exportando somente a estrutura das tabelas que não teram dados
# ------------------------------------------------------------------------------------------------------------------

ignore_tables=""
tmp_file_other=$(mktemp /tmp/XXXXX.sql)
get_tmp_files ${tmp_file_other}

echo "mysqldump --no-data -h 127.0.0.1 -u ${config['user_db']} -p${config['passwd_db']} ${config['database']} > ${tmp_file_other}" > ${tmp_file_other}
sshpass -p ${config['passwd_server']} scp ${tmp_file_other} ${config['user_server']}@${config['host']}:${tmp_file_other}
time sshpass -p ${config['passwd_server']} ssh ${config['user_server']}@${config['host']} "chmod +x ${tmp_file_other}; ${tmp_file_other}"

sshpass -p ${config['passwd_server']} scp ${config['user_server']}@${config['host']}:${tmp_file_other} ${tmp_file_other}

yes_tables=$(egrep -i 'create table' ${tmp_file_other} | egrep -iv '(tbstoragelist)|(tbfilaitem)|(log)' | sed 's/\/\*!50001 //g' | cut -d ' ' -f '3' | sed 's/`//g' | tr '\n' ' ')
for table in ${yes_tables}; do
	ignore_tables=$(echo "${ignore_tables} --ignore-table=${config['database']}.${table}")
done

echo "mysqldump --no-data ${ignore_tables# } -h 127.0.0.1 -u ${config['user_db']} -p${config['passwd_db']} ${config['database']} > ${tmp_file_other}" > ${tmp_file_other}
sshpass -p ${config['passwd_server']} scp ${tmp_file_other} ${config['user_server']}@${config['host']}:${tmp_file_other}
time sshpass -p ${config['passwd_server']} ssh ${config['user_server']}@${config['host']} "chmod +x ${tmp_file_other}; ${tmp_file_other}"

sshpass -p ${config['passwd_server']} scp ${config['user_server']}@${config['host']}:${tmp_file_other} ${tmp_file_other}

echo "" >> ${tmp_file}
cat ${tmp_file_other} >> ${tmp_file}

# ------------------------------------------------------------------------------------------------------------------
# importando banco remoto para local
# ------------------------------------------------------------------------------------------------------------------

mysql -h 127.0.0.1 -u mkommerce -p12345678 --execute="CREATE DATABASE ${tmp_name_db}"
time mysql -h 127.0.0.1 -u mkommerce -p12345678 ${tmp_name_db} < ${tmp_file}

# ------------------------------------------------------------------------------------------------------------------
# views, triggers, procedures
# ------------------------------------------------------------------------------------------------------------------

tmp_file_view=$(mktemp /tmp/view-XXXXX.sql)
tmp_file_trigger=$(mktemp /tmp/trigger-XXXXX.sql)
tmp_file_procedure=$(mktemp /tmp/procedure-XXXXX.sql)
get_tmp_files ${tmp_file_view}
get_tmp_files ${tmp_file_trigger}
get_tmp_files ${tmp_file_procedure}

wget -O - "https://${config['domain']}/ferramentas/join-create-views" > ${tmp_file_view}
wget -O - "https://${config['domain']}/ferramentas/join-create-procedures" > ${tmp_file_procedure}
wget -O - "https://${config['domain']}/ferramentas/join-create-triggers" > ${tmp_file_trigger}

for sql in /tmp/{view,trigger,procedure}*.sql; do
	mysql -h 127.0.0.1 -u mkommerce -p12345678 ${tmp_name_db} < ${sql}
done

for file in ${tmp_arr[@]}; do
	rm ${file}
done
