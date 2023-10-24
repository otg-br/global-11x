local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)			npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)		npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)		end
function onThink()		npcHandler:onThink()		end

local voices = { {text = 'Ola, sou o assistente da staff, fale comigo para receber informations sobre staff.'} }
if VoiceModule then
    npcHandler:addModule(VoiceModule:new(voices))
end

-- Contact
keywordHandler:addKeyword({'contato'}, StdModule.say, {npcHandler = npcHandler, text = 'Entre em contato conosco... pelo E-Mail: contato@ultratibia.com Ou pelo Help Channel'})
keywordHandler:addKeyword({'contact'}, StdModule.say, {npcHandler = npcHandler, text = 'Contact us... by E-Mail: contato@ultratibia.com or send mensage in Help Channel'})
keywordHandler:addKeyword({'contactar'}, StdModule.say, {npcHandler = npcHandler, text = 'Contactenos... por E-Mail: contato@ultratibia.com or envia una mensage en Help Channel'})

-- Methods
keywordHandler:addKeyword({'metodos'}, StdModule.say, {npcHandler = npcHandler, text = 'Querido jogador temos os seguintes metodos: PIX, PICPAY, MERCADO PAGO e TIBIA COINS GLOBAL.  Ao se decidir entre em contato conosco no Help ou voce pode nos enviar um Email para: contato@ultratibia.com'})
keywordHandler:addKeyword({'methods'}, StdModule.say, {npcHandler = npcHandler, text = 'Dear player, we have the following methods: PIX, PICPAY and TIBIA COINS GLOBAL. When you decide, contact us at Help or you can send us an Email to: contato@ultratibia.com'})
keywordHandler:addKeyword({'methodos'}, StdModule.say, {npcHandler = npcHandler, text = 'Estimado jugador, contamos con los siguientes methodos: PIX, PICPAY y TIBIA COINS GLOBAL. Cuando lo decida, contactenos en Help Channel o puede enviarnos un correo electronico a: contato@ultratibia.com'})

-- Donate
keywordHandler:addKeyword({'donate'}, StdModule.say, {npcHandler = npcHandler, text = 'Querido jogador, temos inumeras promocoes especiais para voce, quando voce donata no UltraTibia voce recebe Double Pontos e ainda recebe um pacote de bonus. Se voce possui alguma duvida nao exite em nos procurar nos canais Help.'})
keywordHandler:addKeyword({'donation'}, StdModule.say, {npcHandler = npcHandler, text = 'Dear player, we have numerous special promotions for you, when you donate at UltraTibia you receive Double Points and even receive a bonus package. If you have any doubts, dont hesitate to look for us on the Help channels.'})
keywordHandler:addKeyword({'donar'}, StdModule.say, {npcHandler = npcHandler, text = 'Estimado jugador, tenemos numerosas promociones especiales para usted, cuando dona en UltraTibia recibe puntos dobles e incluso recibe un paquete de bonificacion. Si tienes dudas, no dudes en buscarnos en los canales de Help.'})

-- Promote
keywordHandler:addKeyword({'promocao'}, StdModule.say, {npcHandler = npcHandler, text = 'Querido jogador, nossa promotion atual voce pode conferir em nosso site.'})
keywordHandler:addKeyword({'promotion'}, StdModule.say, {npcHandler = npcHandler, text = 'Dear player, our current promotion you can check on our website.'})
keywordHandler:addKeyword({'promocion'}, StdModule.say, {npcHandler = npcHandler, text = 'Estimado jugador, nuestra promoción vigente la puedes consultar en nuestra web.'})

-- Language
keywordHandler:addKeyword({'portugues'}, StdModule.say, {npcHandler = npcHandler, text = 'Querido jogador, posso te ajudar com informations sobre {Donate}, {Metodos}, {Promocao} ou {Contato}.'})
keywordHandler:addKeyword({'ingles'}, StdModule.say, {npcHandler = npcHandler, text = 'Dear player, i can help you with information about {Donation}, {Methods}, {Promotion} or {Contact}.'})
keywordHandler:addKeyword({'espanhol'}, StdModule.say, {npcHandler = npcHandler, text = 'Estimado jugador, puedo ayudarte con informacion sobre {Donar}, {Methodos}, {Promocion} o {Contactar}.'})


npcHandler:setMessage(MESSAGE_GREET, 'Ola caro |PLAYERNAME|, para iniciar o atendimento selecione seu idioma: {portugues}, {ingles} ou {espanhol}.')
npcHandler:setMessage(MESSAGE_FAREWELL, 'Obrigado amigo jogador, divulgue nossas Pack Donate para seus amiguinhos.')
npcHandler:setMessage(MESSAGE_WALKAWAY, 'Volte logo.')

npcHandler:addModule(FocusModule:new())
