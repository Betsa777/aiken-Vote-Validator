use aiken/collection/dict
use aiken/collection/list
use aiken/interval
use cardano/address.{Address, Script}
use cardano/assets
use cardano/transaction.{
  InlineDatum, Input, Output, OutputReference, Transaction, placeholder,
}
use types.{Add, Create, ElectionDatum, Vote}
use vote

//Create election
test create() {
  let oref = OutputReference { transaction_id: #"aaaa", output_index: 1 }
  let electionsBytesArray = [#"aaaa", #"bbbb"]
  let idElection = #"cccc"
  let name = "name"
  let period = 25000
  let scriptHash = #"dddd"
  let electionDatum =
    ElectionDatum {
      elections: electionsBytesArray,
      participants: dict.empty,
      periods: dict.empty,
      names: dict.empty,
      votes: dict.empty,
      votants: dict.empty,
    }
  trace assets.from_lovelace(2)
  let electionIn =
    Input {
      output_reference: oref,
      output: Output {
        address: Address {
          payment_credential: Script(scriptHash),
          stake_credential: None,
        },
        value: assets.from_lovelace(2),
        datum: InlineDatum(electionDatum),
        reference_script: None,
      },
    }
  let newElectionDatum =
    ElectionDatum {
      elections: list.push(electionsBytesArray, idElection),
      participants: dict.empty,
      periods: electionDatum.periods |> dict.insert(idElection, period),
      names: electionDatum.names |> dict.insert(idElection, [name]),
      votes: dict.empty,
      votants: dict.empty,
    }
  let newElectionOut =
    Output {
      address: Address {
        payment_credential: Script(scriptHash),
        stake_credential: None,
      },
      value: assets.from_lovelace(2),
      datum: InlineDatum(newElectionDatum),
      reference_script: None,
    }

  let tx =
    Transaction {
      ..placeholder,
      inputs: [electionIn],
      outputs: [newElectionOut],
    }
  let action = Create { idElection, name, period }
  vote.vote.spend(Some(electionDatum), action, oref, tx)
}

//Add participant
test add() {
  let oref = OutputReference { transaction_id: #"aaaa", output_index: 1 }
  let electionsBytesArray = [#"aaaa", #"bbbb"]
  let participantAddress = #"cccc"
  let scriptHash = #"dddd"
  let idElection = #"aaaa"
  let action = Add { address: participantAddress, idElection }
  let electionDatum =
    ElectionDatum {
      elections: electionsBytesArray,
      participants: dict.empty,
      periods: dict.empty,
      names: dict.empty,
      votes: dict.empty,
      votants: dict.empty,
    }
  let electionIn =
    Input {
      output_reference: oref,
      output: Output {
        address: Address {
          payment_credential: Script(scriptHash),
          stake_credential: None,
        },
        value: assets.from_lovelace(2),
        datum: InlineDatum(electionDatum),
        reference_script: None,
      },
    }
  trace @"scriptHash is "
  trace Script(scriptHash)
  let newElectionDatum =
    ElectionDatum {
      elections: electionsBytesArray,
      participants: dict.empty |> dict.insert(idElection, [participantAddress]),
      periods: dict.empty,
      names: dict.empty,
      votes: dict.empty,
      votants: dict.empty,
    }
  let electionOut =
    Output {
      address: Address {
        payment_credential: Script(scriptHash),
        stake_credential: None,
      },
      value: assets.from_lovelace(2),
      datum: InlineDatum(newElectionDatum),
      reference_script: None,
    }
  let tx =
    Transaction { ..placeholder, inputs: [electionIn], outputs: [electionOut] }
  vote.vote.spend(Some(electionDatum), action, oref, tx)
}

//Vote 

test vote() {
  let oref = OutputReference { transaction_id: #"aaaa", output_index: 1 }
  let electionsBytesArray = [#"aaaa", #"bbbb"]
  let scriptHash = #"ffff"
  let addressP = #"dddd"
  let addressV = #"eeee"
  let period = 25000
  let vote = 1
  let idElection = #"aaaa"
  let electionDatum =
    ElectionDatum {
      elections: electionsBytesArray,
      participants: dict.empty |> dict.insert(idElection, [addressP]),
      periods: dict.empty |> dict.insert(idElection, period),
      names: dict.empty,
      votes: dict.empty,
      votants: dict.empty,
    }
  let electionIn =
    Input {
      output_reference: oref,
      output: Output {
        address: Address {
          payment_credential: Script(scriptHash),
          stake_credential: None,
        },
        value: assets.from_lovelace(2),
        datum: InlineDatum(electionDatum),
        reference_script: None,
      },
    }
  let newElectionDatum =
    ElectionDatum {
      elections: electionsBytesArray,
      participants: dict.empty |> dict.insert(idElection, [addressP]),
      periods: electionDatum.periods,
      names: dict.empty,
      votes: electionDatum.votes
        |> dict.insert(idElection, dict.empty |> dict.insert(addressP, vote)),
      votants: dict.empty |> dict.insert(idElection, [addressV]),
    }
  trace newElectionDatum.votes
  let electionOut =
    Output {
      address: Address {
        payment_credential: Script(scriptHash),
        stake_credential: None,
      },
      value: assets.from_lovelace(2),
      datum: InlineDatum(newElectionDatum),
      reference_script: None,
    }
  let action = Vote { addressP, addressV, idElection }
  let tx =
    Transaction {
      ..placeholder,
      inputs: [electionIn],
      outputs: [electionOut],
      validity_range: interval.between(10000, 25000),
    }
  trace tx.validity_range
  vote.vote.spend(Some(electionDatum), action, oref, tx)
}
