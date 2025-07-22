use aiken/collection/dict
use aiken/collection/list
use aiken/interval
// use cardano/address.{Script}
use cardano/transaction.{InlineDatum, OutputReference, Transaction}
use types.{Actions, Add, Create, ElectionDatum, Vote}

pub fn election_exist(elections: List<ByteArray>, election: ByteArray) -> Bool {
  list.any(elections, fn(el) { el == election })
}

validator vote {
  spend(
    _datum: Option<ElectionDatum>,
    redeemer: Actions,
    oref: OutputReference,
    tx: Transaction,
  ) {
    let Transaction { inputs, outputs, validity_range, .. } = tx
    when redeemer is {
      Add { address, idElection } -> {
        expect Some(input) =
          list.find(inputs, fn(input) { input.output_reference == oref })
        let scriptHash = input.output.address.payment_credential
        expect Some(output) =
          list.find(
            outputs,
            fn(output) { output.address.payment_credential == scriptHash },
          )
        //Verifier que l'election existe bien
        //Il faut verifier que le bon datum est stocké on-chain
        expect InlineDatum(inputDatum) = input.output.datum
        expect ElectionDatum { elections, participants, .. } = inputDatum
        //Je recupère l'id de l'election si elle existe
        expect Some(election) =
          list.find(elections, fn(election) { election == idElection })
        //Je m'assure que le participant n'etait pas dejà dans l'election
        expect None =
          when dict.get(participants, election) is {
            Some(participantsBefore) -> {
              trace participantsBefore
              list.find(
                participantsBefore,
                fn(participant) { participant == address },
              )
            }
            None -> None
          }
        //Il faut s'assurer qu'un participant a été ajouté et qu'il n'existait pas encore
        //Il faut s'assurer qu'il est dans le nouveau datum(output.datum)
        expect InlineDatum(ouputDatum) = output.datum
        expect ElectionDatum { participants, .. } = ouputDatum
        expect Some(participantsAfter) = dict.get(participants, election)
        //Je m'assure qu'en sortie le nouveau participant a été ajouté à l'election
        list.any(participantsAfter, fn(participant) { participant == address })
      }

      //Creer une election
      //n'importe qui peut créer une election
      //idElection est le hash sur 256 bits du name de l'election et du temps de creation
      //Il ne doit pas y avoir deux elections avec le meme idElection
      Create { idElection, name, period } -> {
        expect Some(input) =
          list.find(inputs, fn(input) { input.output_reference == oref })
        //Hash du script
        let scriptHash = input.output.address.payment_credential

        expect Some(output) =
          list.find(
            outputs,
            fn(output) { output.address.payment_credential == scriptHash },
          )
        //Je recupère le datum de l'UTXO en input
        expect InlineDatum(inputDatum) = input.output.datum
        expect ElectionDatum { elections, .. } = inputDatum
        trace inputDatum
        // expect Some(result) =
        //Je m'assure qu'il n'ya pas d'elections avec le meme id
        let electionIdBefore =
          list.any(elections, fn(election) { election == idElection })
        //Je dois m'assurer que l'election a été ajouté en output
        expect InlineDatum(ouputDatum) = output.datum
        expect ElectionDatum { elections, names, periods, .. } = ouputDatum
        trace ouputDatum
        let electionIdAfter =
          list.any(elections, fn(election) { election == idElection })
        //Je recupère les noms
        expect Some(namesInDatum) = dict.get(names, idElection)
        //Je reupère la periode
        expect Some(p) = dict.get(periods, idElection)
        //Je m'assure que le name de l'election a été ajouté en output
        let nameResult = list.any(namesInDatum, fn(n) { n == name })
        and {
          electionIdBefore == False,
          electionIdAfter,
          nameResult,
          name != "",
          p == period,
          period > 0,
        }
      }
      //addresse du participant qu'on vote
      //l'id de l'election dans a laquelle on vote
      Vote { addressP, addressV, idElection } -> {
        //s'assurer que le votant n'a pas encore voté a cette election
        expect Some(input) =
          list.find(inputs, fn(input) { input.output_reference == oref })
        let scriptHash = input.output.address.payment_credential
        expect InlineDatum(datum) = input.output.datum
        expect ElectionDatum {
          elections,
          votants,
          participants,
          votes,
          periods,
          ..
        } = datum
        //Je m'assure que le votant n'avait pas dejà voté dans cette election
        expect None =
          when dict.get(votants, idElection) is {
            Some(votantsBefore) ->
              list.find(votantsBefore, fn(vt) { vt == addressV })
            None -> None
          }
        expect Some(participantToElection) = dict.get(participants, idElection)
        //Je recupère la periode de validité de l'election
        expect Some(period) = dict.get(periods, idElection)
        //Verifier que l'election existe
        expect Some(_) = list.find(elections, fn(el) { el == idElection })
        //Verifier que le participant existe
        expect Some(_) =
          list.find(participantToElection, fn(p) { p == addressP })
        //Recupérer le nombre de votes pour ce participant en input
        let participantVotes =
          when dict.get(votes, idElection) is {
            Some(p) -> p
            None -> dict.empty
          }
        let numberOfVotesBefore =
          when dict.get(participantVotes, addressP) is {
            Some(v) -> v
            //0 dans le cas ou il n'yavait pas de vote pour ce participant
            None -> 0
          }
        trace numberOfVotesBefore
        expect Some(output) =
          list.find(
            outputs,
            fn(output) { output.address.payment_credential == scriptHash },
          )
        expect InlineDatum(datum) = output.datum
        expect ElectionDatum { votants, votes, .. } = datum
        expect Some(votantsAfter) = dict.get(votants, idElection)
        trace votantsAfter
        expect Some(participantVotes) = dict.get(votes, idElection)
        expect Some(numberOfVotesAfter) = dict.get(participantVotes, addressP)
        trace numberOfVotesAfter
        //Verifier que le votant a été ajouté a ceux qui ont voté a l'election
        expect Some(_) = list.find(votantsAfter, fn(vt) { vt == addressV })
        //Je defini les intervals sachant que si validity_range est egale
        //a periode alors ca passe toujours 
        //Je cree un iterval jusqua period inclus
        let periodInterval = interval.before(period)
        trace periodInterval
        //Je recupère le plus petit interval entre les deux
        let smallestInterval = interval.hull(periodInterval, validity_range)
        trace smallestInterval
        and {
          (numberOfVotesBefore + 1 == numberOfVotesAfter)?,
          (smallestInterval == periodInterval)?,
        }
      }
    }
    //Je veux le max
  }

  else(_) {
    fail
  }
}
