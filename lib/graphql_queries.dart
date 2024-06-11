const String getLinksQuery = """
query getLink{
  superheroe{
    id
    name 
    image
    characteristics
    postedBy{
      username
    }
    votes{
      id
    }
  }
}
""";

const String createUserMutation = """
mutation createUser(\$email: String!, \$password: String!, \$username: String!){
  createUser(email: \$email, password: \$password, username: \$username){
    user{
      email
      username
      password
    }
  }
}
""";

const String createLinkMutation = """
mutation createLink(\$name: String!, \$characteristics: String!, \$image: String!){
  createSuperheroe(name: \$name, characteristics: \$characteristics, image: \$image) {
    id
    characteristics
    image
    name
  }
}
""";

const String tokenAuthMutation = """
mutation tokenAuth(\$username: String!, \$password: String!){
  tokenAuth(username: \$username, password: \$password){
    token
  }
}
""";

const String createVoteMutation = """
mutation createVote(\$superheroeId: Int!){
  createVote(superheroeId: \$superheroeId){
    user{
      username
    }
  }
}
""";
