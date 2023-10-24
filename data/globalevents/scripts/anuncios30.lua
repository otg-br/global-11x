local messages = {
	"Encontrou algum bug ou quer ter contato com mais jogadores? Participe do nosso grupo no Whatsapp!",
	"Seja um apoiador e ajude o servidor a crescer: faça uma doação e ganhe acesso ao conteúdo da nossa store!",
	"Não conhece os comandos do servidor?\n Utilize o comando !commands e seja feliz. :)",
	"Dificuldades no level up ou não consegue dropar aquele item? Seja VIP e ganhe vantagens exclusivas! :)",
	"Donatou via PagSeguro/PayPal e não caíram suas moedas? Crie um ticket em nosso site. Doações via PicPay devem ser confirmadas no account management com as informações da compra.",
	"Atenção: EVITEM usar senhas de outros servidores aqui no UltraTibia. Jogadores estão sendo hackeados por este motivo e, se o número de casos for muito alto, será impossível ajudar a todos.",

}

function onThink(interval)
	local msg = messages[math.random(#messages)]
	Game.broadcastMessage(msg, MESSAGE_EVENT_ADVANCE)
	return true
end