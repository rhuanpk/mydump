#!/usr/bin/env bash

####################################################################################################
#
# PENDENCIAS:
# - fazer com que mesmo um arquivo já exista, criar outro personalizado; (V)
# - fazer com que seja possível excluir arquivos de configuração; (V)
# - poder editar informações de um arquivo já existente; ()
# - poder excolher vizualmente qual arquivo quer usar; ()
# - fazer uma barra de progresso; ()
# - suprimir erros esperados; (V)
# - cirar os arquivos de log e opção para poder acessalos diretamente pelo programa; (/)
# - testar conexão ssh via ip, caso não retorne positivo, tente via dominio, caso falhe, exite, mostrando para o usuário; (V)
# - dropar o banco casa já exista; (V)
# - jogar o time para a saida de erro mesmo e depois pegar o time do processo e dar um cat nele; ()
# - validar se tem algum arquivo de configuração já existente ()
# - criar opção no menu para exportar ou não tabelas de log
#
####################################################################################################

# -------------------------------------------------------------------------------------------------------------------
# importação de arquivos necessários
# -------------------------------------------------------------------------------------------------------------------

# biblioteca pessoal compartilhada
source /usr/local/lib/mydump/common-properties.lib

# -------------------------------------------------------------------------------------------------------------------
# declaração de funções
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
	prox_cont=$(find ${mydump_path} -name "*${config['database']}*" | sort | tail -n +$(find ${mydump_path} -name "*${config['database']}*" | wc -l) | egrep -o '(__[0-9]){1}' | cut -c '3-')
	if [ ${cont} -gt 1 ]; then
		path_completo="${mydump_path}/${config['database']}__$((${prox_cont}+1)).conf"
		touch ${path_completo}
		menu_coleta_info
	else
		old_file="${mydump_path}/${config['database']}__0.conf"
		mv ${path_completo} ${old_file} 2>>${file_log}
		path_completo="${mydump_path}/${config['database']}__$((${prox_cont}+1)).conf"
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
	read -p "Para continuar o banco será DROPADO! [yes/NO] " answer
	[ "${answer,,}" != "yes" ] && exit 0
	tmp_file_path=${1}
	cont=1
	for index in ${ordenacao}; do
		config["${index}"]=$(sed -n ${cont}p ${tmp_file_path})
		let ++cont
	done
	tmp_name_db=${config['database_local']}
}

# -------------------------------------------------------------------------------------------------------------------
# declaração de variáveis
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

#####################################################################################################################
# 
# inicio do programa
#
#####################################################################################################################

touch ${fixed_tmp_files[@]}

[ ! -e ${mydump_path} ] && mkdir -v ${mydump_path}
read -p "Entre com o nome do banco a ser exportado: " config['database']
config_file="${config['database']}.conf"
path_completo="${mydump_path}/${config_file}"
config_files_all="$(find ${mydump_path} -name "*${config['database']}*" | sort)"

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
		cod_file=1
		echo "--> Arquivos de configuração já existentes <--"
		echo "---------------------------------------------------------------------------"
		for tmp_index in $(tr '\n' ' ' <<< ${config_files_all}); do
			cont=1
			for index in ${ordenacao}; do
				if [ "${index}" = "database" ]; then
					echo "*** cod [${cod_file}]: ${config['database']}.conf ***"
					echo -e "${config_name[${index}]}: $(sed -n ${cont}p ${tmp_index})"
				else
					echo -e "${config_name[${index}]}: $(sed -n ${cont}p ${tmp_index})"
				fi
				let ++cont
			done
			echo "---------------------------------------------------------------------------"
			let ++cod_file
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
			*) read -p "Opção inválida! <press enter> " readkey; clear ;;
		esac
	done
fi

read -p "Porta SSH (<enter> para não especificar): " config['port']

for config_var in ${!config[@]}; do
	echo ${config_var}:${config[${config_var}]} >> ${fixed_tmp_files['coleta_info_file']}
done

tmp_line=$(cat -n '/etc/ssh/ssh_config' | egrep '.*(#)+.*(ConnectTimeout)+.*' | cut -c 5-7 | sed 's/\t$//')
if [ ! -z ${tmp_line} ]; then
	echo -e "${passwd_sudo}\n" | sudo -S sed -i "${tmp_line}s/^#/ /" /etc/ssh/ssh_config && echo -e "${passwd_sudo}\n" | sudo -S sed -i "${tmp_line}s/0/15/" /etc/ssh/ssh_config
fi

# Recebe a quantidade de colunas do tamanho da tela atual em que o programa é invocado "-17" porque é o tamanho total da "loading bar"
echo $(($(tput cols)-17)) > ${fixed_tmp_files['terminal_cols_tmp_file']}

while :; do
	sleep 1.5
	if ! ps -o pid,command -C bash | grep -Ei '(loading-bar)' >&/dev/null; then
		kill -9 $(ps -o pid -C multitail | tail -1) 2>&-
		for file in ${fixed_tmp_files[@]}; do
			rm ${file}
		done
		break
	fi
done &

multitail -D -l mydump-principal -wh 3 -i ${fixed_tmp_files['loading_bar_file']}

clear
