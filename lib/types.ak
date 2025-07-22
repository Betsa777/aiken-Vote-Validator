use aiken/collection/dict.{Dict}

pub type Actions {
  //creer une election(identifiant de l'election, nom de l'election + periode de validité de l'election)
  Create { idElection: ByteArray, name: ByteArray, period: Int }
  //Ajouter un participant(addresse, electionId)
  Add { address: ByteArray, idElection: ByteArray }
  //addressP -> addresse du participant à voter
  //addressV ->adresse du votant
  Vote { addressP: ByteArray, addressV: ByteArray, idElection: ByteArray }
}

pub type ElectionDatum {
  //id_election donne les participants a l'election
  participants: Dict<ByteArray, List<ByteArray>>,
  elections: List<ByteArray>,
  //id de l'election renvoie sa periode de durée
  periods: Dict<ByteArray, Int>,
  //noms des elections a partir de electionId
  names: Dict<ByteArray, List<ByteArray>>,
  //idElection -> Particpants -> nombre de votes
  votes: Dict<ByteArray, Dict<ByteArray, Int>>,
  //idElection -> addresse de ceux qui ont voté
  votants: Dict<ByteArray, List<ByteArray>>,
}
