import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'graphql_config.dart';
import 'graphql_queries.dart';
import 'login_page.dart';
import 'create_link_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: ValueNotifier(getGraphQLClient()),
      child: CacheProvider(
        child: MaterialApp(
          title: 'Superheroes',
          theme: ThemeData(
            primarySwatch: Colors.red,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: MyHomePage(),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? token;
  VoidCallback? _refetch;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  void _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token');
    });
  }

  void _onLogin(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    setState(() {
      this.token = token;
    });
  }

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    setState(() {
      token = null;
    });
  }

  void _onLinkCreated() {
    if (_refetch != null) {
      _refetch!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'API Superheroes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red[900],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              if (_refetch != null) {
                _refetch!();
              }
            },
          ),
          if (token == null)
            IconButton(
              icon: Icon(Icons.login, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginPage(onLogin: _onLogin),
                  ),
                );
              },
            ),
          if (token != null) ...[
            IconButton(
              icon: Icon(Icons.add, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateLinkPage(
                      token: token!,
                      onLinkCreated: _onLinkCreated,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.logout, color: Colors.white),
              onPressed: _logout,
            ),
          ],
        ],
      ),
      backgroundColor: Colors.red[50],
      body: Column(
        children: [
          Expanded(
            child: Query(
              options: QueryOptions(
                document: gql(getLinksQuery),
              ),
              builder: (QueryResult result,
                  {VoidCallback? refetch, FetchMore? fetchMore}) {
                if (result.hasException) {
                  return Center(child: Text(result.exception.toString()));
                }

                if (result.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }

                _refetch = refetch;

                List links = result.data!['superheroe'];

                return ListView.builder(
                  itemCount: links.length,
                  itemBuilder: (context, index) {
                    final link = links[index];

                    return Card(
                      margin:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      elevation: 5,
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16.0),
                        leading: link['image'] != null
                            ? Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  image: DecorationImage(
                                    image: NetworkImage(link['image']),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              )
                            : Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.grey,
                                ),
                                child: Icon(Icons.image, color: Colors.white),
                              ),
                        title: Text(
                          link['name'],
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              link['characteristics'],
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            Text(
                              '${link['votes'].length} likes || Publicado por: ${link['postedBy']['username']}',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: token != null
                            ? IconButton(
                                icon: Icon(Icons.thumb_up,
                                    color: Colors.red[400]),
                                onPressed: () async {
                                  final client = getGraphQLClient(token: token);
                                  await client.mutate(
                                    MutationOptions(
                                      document: gql(createVoteMutation),
                                      variables: {
                                        'superheroeId': link['id'],
                                      },
                                    ),
                                  );
                                  refetch!();
                                },
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
