# @version ^0.3.7

"""
*Representa un registro de las ruletas
-Contiene informacion de todas las ruletas
+Estadistica general de un determinado usuario
+Estadistica general de una determinada ruleta
"""

struct RouletteData:    #Representa una ruleta
    totalBalance: uint256
    winnerNumber: uint256
    id: uint256
    accounts: DynArray[address,100] #Cuentas que apostaron en esta ruleta

struct Bet: #Representa una apuesta
    betNumber: uint256
    betAmount: uint256
    idRoulette: uint256

#Estado de la ruleta
enum RouletteStates:
    ANY
    STARTED
    ENDED

#Contiene la informacion de una apuesta x un address en una ruleta en particular
gamblersBets: HashMap[address, HashMap[uint256, Bet]]

#Ruletas actuales participantes
rouletteCount: uint256
#Contiene la informacion de una ruleta determinada
roulettesData: HashMap[uint256, RouletteData]
#Contiene las cuentas de los usuarios que apostaron por un determinado numero en una determinada ruleta
rouletteResults: HashMap[uint256, HashMap[uint256, DynArray[address,100]]]
#Contiene el estado en el que se encuentra una ruleta
rouletteStatus: HashMap[uint256, RouletteStates]

#Propietario del contrato
owner: address

@external
def __init__():
    self.owner = msg.sender

@external
def regRoulette() -> uint256:    #Registra una ruleta nueva
    tempId: uint256 = self.rouletteCount
    self.roulettesData[tempId] = RouletteData({
        totalBalance: 0,
        winnerNumber: 0,
        id: tempId,
        accounts: []
    })
    self.rouletteStatus[tempId] = RouletteStates.STARTED
    self.rouletteCount += 1
    return tempId

@external
def regBet(_number:uint256, _amount:uint256, _account:address, _idRoulette:uint256):    #Registra una apuesta en una ruleta
    assert self.rouletteStatus[_idRoulette] == RouletteStates.STARTED, "This roulette hasn't started yet"
    
    #Actualizo datos de una ruleta
    self.roulettesData[_idRoulette].accounts.append(_account)
    self.roulettesData[_idRoulette].totalBalance += _amount
    #Agrego al jugador a la lista de cuentas que votaron por el numero X en la ruleta 
    self.rouletteResults[_idRoulette][_number].append(_account)

    betTemp:Bet = Bet({
        betNumber: _number,
        betAmount: _amount,
        idRoulette: _idRoulette
    })
    #Actualizo datos del jugador
    self.gamblersBets[_account][_idRoulette] = betTemp

@view
@internal
def _generateRandomNumber(_seed:uint256) -> uint256:    #Genero numero random apartir de un seed
    random_num: uint256 = (block.number * block.timestamp + 598 * _seed)
    return random_num % 36
#No es del todo seguro, se debería hacer uso de una funcion externa
#Pero para ejemplos prácticos va bien

@external
def finishBet(_idRoulette:uint256, _seed:uint256) -> uint256:  #Indica que en una ruleta termino el tiempo de apuestas y genera el numero ganador
    assert self.rouletteStatus[_idRoulette] == RouletteStates.STARTED, "This roulette hasn't started yet"
    #Genero numero
    _theNumber: uint256 = self._generateRandomNumber(_seed)
    #Actualizo datos de la ruleta
    self.rouletteStatus[_idRoulette] = RouletteStates.ENDED
    self.roulettesData[_idRoulette].winnerNumber = _theNumber
    return _theNumber 

@view
@external
def isWinner(_idRoulette:uint256, _number:uint256, _account:address) -> bool:   #Indica si un jugador ganó
    assert self.rouletteStatus[_idRoulette] == RouletteStates.ENDED, "This roulette isn't over yet"
    if self.gamblersBets[_account][_idRoulette].betNumber == _number:
        return True
    return False

@view
@external
def showProffit(_idRoulette:uint256, _account:address) -> uint256:  #Muestra el total recaudado por un jugador
    assert self.rouletteStatus[_idRoulette] == RouletteStates.ENDED, "This roulette isn't over yet"
    return self.gamblersBets[_account][_idRoulette].betAmount * 2

@view
@external
def showWinners(_idRoulette:uint256, _number:uint256) -> DynArray[address,100]: #Devuelve los ganadores de una ruleta
    assert self.rouletteStatus[_idRoulette] == RouletteStates.ENDED, "This roulette isn't over yet"
    return self.rouletteResults[_idRoulette][_number]

@view
@external
def showMembers(_idRoulette:uint256) -> DynArray[address,100]:  #Devuelve la lista de jugadores que apostaron en una ruleta
    return self.roulettesData[_idRoulette].accounts

@view
@external
def alreadyBet(_idRoulette:uint256, _account:address) -> bool:  #Indica si un jugador ya realizó una apuesta
    _amount: uint256 = self.gamblersBets[_account][_idRoulette].betAmount
    if _amount == 0:
        return False
    return True

@view
@external
def showMyBet(_idRoulette:uint256, _account:address) -> DynArray[uint256,2]: #Devuelve la apuesta de un jugador
    _response: DynArray[uint256,2] = []
    _response.append(self.gamblersBets[_account][_idRoulette].betNumber)
    _response.append(self.gamblersBets[_account][_idRoulette].betAmount)
    return _response

@view
@external
def showRouletteBalance(_idRoulette:uint256) -> uint256:    #Devuelve la suma de apuestas de una ruleta
    return self.roulettesData[_idRoulette].totalBalance