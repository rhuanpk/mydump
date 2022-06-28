#!/usr/bin/env bash

# source /opt/mydump/lib/common-properties.lib
source /usr/local/lib/mydump/common-properties.lib

# ********** Declaração de Funções **********

# Atualiza o valor da flag que mantem a "loading bar" pausada
refresh_sleep_flag() {
	SLEEP_FLAG=$(cut -d ':' -f 2 ${sleep_flag_file})
	${SLEEP_FLAG:=false}
}

# ********** Declaração de Variáveis **********

# Recebe a quantidade de passos que terá no programa
MAX_STEPS=$(cut -d ':' -f 2 ${max_stps_flg_file})
# Seta o vlaor inicial da flag que mantem a "loading bar" pausada como false para conseguir entrar no fluxo normal do programa
SLEEP_FLAG=false
# Recebe a quantidade de colunas do tamanho da tela atual em que o programa é invocado "-17" porque é o tamanho total da "loading bar"
terminal_cols=$(cat ${terminal_cols_tmp_file})

# ********** Início do Programa **********	

# Loop para fazer a variável da "loading bar" receber a própria "loading bar" por completo
for i in $(seq ${terminal_cols}); do
	loadbar_size=${loadbar_size}#
done

# Recebe o tamanho total da "loading bar"
max_loadbar_size=${#loadbar_size}

for index in $(seq 1 ${MAX_STEPS}); do
	
	percentual=$(($((${index}*100))/${MAX_STEPS}))
	percentual_bar=$(($((${percentual}*${max_loadbar_size}))/100))
	
	# Printa a loading-bar em um arquivo
	echo -e "\n\nProgress: [${loadbar_size:0:${percentual_bar}}] ${percentual}%" >> ${loading_bar_file}

	# Loop que segura a "loading bar" até poder ser printada novamente mediante 'refresh' da variável
	while :; do
		if ${SLEEP_FLAG}; then
			break
		fi
		refresh_sleep_flag
	done

	set_sleep_flag false
	refresh_sleep_flag

done
