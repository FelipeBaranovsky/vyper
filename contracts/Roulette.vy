# @version ^0.3.7

"""
*Representa el juego clásico de la ruleta de los casinos
-Los jugadores apuestan a un solo numero
-Si aciertan, duplican lo apostado
-Si fallan, pierden todo
"""

#Interfaz del contrato Leaderboard el cual almacena los datos y mantiene un registro de multiples ruletas
interface Leaderboard:
    def Leaderboard(): nonpayable   #Inicializacion
    def regRoulette() -> uint256: nonpayable    #Registra la ruleta actual y asigna un id
    def showMyBet(idRoulette:uint256, sender:address) -> DynArray[uint256,2]: view  #Muestra la apuesta de un jugador X
    def alreadyBet(idRoulette:uint256, sender:address) -> bool: view    #Comprueba si un jugador X ya apostó
    def regBet(_number:uint256, _amount:uint256, _account:address, _idRoulette:uint256): nonpayable #Registra la apuesta de un jugador
    def finishBet(_idRoulette:uint256, _seed:uint256) -> uint256: nonpayable    #Gira la ruleta y devuelve el numero ganador
    def isWinner(_idRoulette:uint256, _number:uint256, _account:address) -> bool: view  #Comprueba si un jugador X ganó
    def showProffit(_idRoulette:uint256, _account:address) -> uint256: view     #Devuelve lo obtenido por un jugador X
    def showWinners(_idRoulette:uint256, _number:uint256) -> DynArray[address,100]: view    #Muestra la lista de ganadores
    def showMembers(_idRoulette:uint256) -> DynArray[address,100]: view     #Muestra todas las cuentas que apostaron en la ruleta
    def showRouletteBalance(_idRoulette:uint256) -> uint256: view   #Devuelve el balance actual de la ruleta

struct Bet:
    betNumber: uint256
    betAmount: uint256  

#Estados en el que se encuentra le juego
enum GameStates:
    INITIALIZED
    WAITING     #Esperando a que los jugadores apuesten
    ENDED
   
owner: address      #Creador del contrato
state: GameStates   #Estado actual del juego
winnerNumber: uint256    #Numero ganador 🤫
idRoulette: uint256     #ID propio -> Me lo da el otro contrato
#*Permite tener la posibilidad de expandir esto y tener un Roulette Factory
#-De esta forma el Leaderboard puede manejar la info de multiples ruletas
contractAddress: address    #Contrato de estadisticas

@external
def __init__():
    self.owner = msg.sender
    self.state = GameStates.INITIALIZED

@external
def startBets(_dirContract: address):    #Inicia el tiempo de apuestas
    assert self.owner == msg.sender, "The owner is the only one who can start the bet"
    assert self.state == GameStates.INITIALIZED, "The game is not in the correct stage"
    self.state = GameStates.WAITING
    self.contractAddress = _dirContract
    self.idRoulette = Leaderboard(self.contractAddress).regRoulette()   #Registra la ruleta en el Leaderboard y devuelve el id asociado

@view
@external
def showIdRoulette() -> uint256:    #Muestra el ID de la ruleta
    assert self.owner == msg.sender, "The owner is the only one who can start the bet"
    return self.idRoulette

@view
@external
def showMyBalance() -> uint256: #Muestra el balance total de la ruleta
    assert self.state != GameStates.INITIALIZED, "The game is not in the correct stage"
    assert self.owner == msg.sender, "The owner is the only one who can start the bet"
    return Leaderboard(self.contractAddress).showRouletteBalance(self.idRoulette)   #Devuelve la sumatoria de todas las apuestas hechas en la ruleta

@view
@internal
def _checkAlreadyBet(_sender:address)-> bool: #Comprueba si un jugador ya apostó
    return Leaderboard(self.contractAddress).alreadyBet(self.idRoulette, _sender)    #Devuelve verdadero si un jugador ya realizó una apuesta

@view
@external
def checkMyBet() -> Bet:   #Devuelve la apuesta realizada x un jugador
    assert self._checkAlreadyBet(msg.sender) == True, "You haven't placed any bets"
    _response: DynArray[uint256,2] = Leaderboard(self.contractAddress).showMyBet(self.idRoulette, msg.sender)   #Devuelve el numero al que apostó un jugador y cuanto apostó
    _bet: Bet = Bet({betNumber:_response[0],betAmount:_response[1]})
    return _bet

@external  
def bet(_number: uint256, _amount: uint256):    #Realiza una apuesta
    assert self.state == GameStates.WAITING, "The game is not in the correct stage"
    assert _number >= 0, "You must choose a number between 0 and 35"
    assert _number <= 35, "You must choose a number between 0 and 35"
    assert _amount > 0, "You must place a bet greater than $0"
    assert self._checkAlreadyBet(msg.sender) == False, "You have already placed a bet"
    Leaderboard(self.contractAddress).regBet(_number, _amount, msg.sender, self.idRoulette) #Registra la apuesta realizada por un jugador

@external
def betFor(_number:uint256, _amount:uint256, _account:address): #Realiza una apuesta x otro jugador
    assert self.owner == msg.sender, "The owner is the only one who can start the bet"
    assert self.state == GameStates.WAITING, "The game is not in the correct stage"
    assert _number >= 0, "You must choose a number between 0 and 35"
    assert _number <= 35, "You must choose a number between 0 and 35"
    assert _amount > 0, "You must place a bet greater than $0"
    assert self._checkAlreadyBet(_account) == False, "You have already placed a bet"
    Leaderboard(self.contractAddress).regBet(_number, _amount, _account, self.idRoulette)   #Registra la apuesta realizada por un jugador elegido por el owner

@external
def endBets(_seed:uint256) -> uint256:   #Finaliza el tiempo de apuestas y gira la ruleta
    assert self.owner == msg.sender, "The owner is the only one who can start the bet"
    assert self.state == GameStates.WAITING, "The game is not in the correct stage"
    self.state = GameStates.ENDED
    self.winnerNumber = Leaderboard(self.contractAddress).finishBet(self.idRoulette, _seed) #Devuelve el numero ganador
    return self.winnerNumber

@view
@internal
def _isWinner() -> bool: #Comprueba si un jugador ganó
    return Leaderboard(self.contractAddress).isWinner(self.idRoulette, self.winnerNumber, msg.sender)   #Devuelve verdadero si un jugador X está entre los ganadores

@view
@external
def showMyProffit() -> uint256:  #Devuelve los beneficios (Apostado + Ganado)
    assert self.state == GameStates.ENDED, "The game is not over"
    assert self._checkAlreadyBet(msg.sender) == True, "You haven't placed any bets"
    assert self._isWinner() == True, "You are not among the winners"
    return Leaderboard(self.contractAddress).showProffit(self.idRoulette, msg.sender)   #Devuelve lo apostado por un jugador X 2

@view
@external
def showNumber() -> uint256:   #Devuelve el numero ganador
    assert self.state == GameStates.ENDED, "The game is not over"
    return self.winnerNumber

@view
@external
def showTheWinners() -> DynArray[address,100]:  #Devuelve la lista de ganadores
    assert self.state == GameStates.ENDED, "The game is not over"
    return Leaderboard(self.contractAddress).showWinners(self.idRoulette, self.winnerNumber)    #Devuelve la lista de cuentas que votaron a un numero X (el ganador)

@view
@external
def showGamblers() -> DynArray[address,100]:    #Devuelve la lista de cuentas que apostaron en la ruleta
    assert self.state == GameStates.ENDED, "The game is not over"
    return Leaderboard(self.contractAddress).showMembers(self.idRoulette)   #Devuelve todos los jugadores que apostaron