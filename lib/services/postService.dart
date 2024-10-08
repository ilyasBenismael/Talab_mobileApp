import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PostService {


  static Future<int> addPost(Map<String, dynamic> postInfos) async {
    try {
      //store the image file in firebasestorage and get its url
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = FirebaseStorage.instance.ref().child('posts/$fileName');
      await ref.putFile(postInfos['imageFile']);
      String downloadURL = await ref.getDownloadURL();

      //store user data in Firestore.
      await FirebaseFirestore.instance.collection('posts').add({
        'title': postInfos['title'],
        'price': postInfos['price'],
        'description': postInfos['description'],
        'categories': postInfos['categories'],
        'imageUrl': downloadURL,
        'tags': null,
        'userId': FirebaseAuth.instance.currentUser!.uid.toString(),
        'comments': 0,
        'timeStamp': FieldValue.serverTimestamp()
      });
      return 1;
    } catch (e) {
      print(e.toString());
      return -1;
    }
  }






  static Future<int> updatePost(Map<String, dynamic> postInfos, bool isImgEdited, String postId, String? previousImgUrl) async {
    try {

      //if anything is empty we wont accept it
      if (postInfos['title'].isEmpty ||
          postInfos['price'].isEmpty ||
          postInfos['description'].isEmpty ||
          postInfos['categories'].isEmpty ||
          postInfos['imageFile'] == null) {
        return -1;
      }

      //if img is edited we put the new imgfile in firebase and get its url and delete the old pic
      if(isImgEdited) {
      //store the image file in firebasestorage and get its url
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = FirebaseStorage.instance.ref().child('posts/$fileName');
      await ref.putFile(postInfos['imageFile']);
      postInfos['imageFile'] = await ref.getDownloadURL();

      if (previousImgUrl != null) {
        FirebaseStorage.instance.refFromURL(previousImgUrl).delete();
      }
      }


      //after this we update the post (saving old timestamp)
      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'title': postInfos['title'],
        'price': postInfos['price'],
        'description': postInfos['description'],
        'categories': postInfos['categories'],
        'imageUrl': postInfos['imageFile'],
        'userId': FirebaseAuth.instance.currentUser!.uid.toString(),
      });
      return 1;
    } catch (e) {
      print(e.toString());
      return -2;
    }
  }


  Future<int> deletePostAndComments(String postId, String? imageUrl) async {
    try {
      // Delete image from Firebase Storage if it exists
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      }

      // Delete post from Firestore
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();

      // Get all comments with the specified postId and delete them
      QuerySnapshot commentsSnapshot = await FirebaseFirestore.instance
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .get();

      for (QueryDocumentSnapshot doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }

      return 1; // Success
    } catch (e) {
      print("Failed to delete post and comments: $e");
      return -1; // Failure
    }
  }




  //returns null if error, an empty list [] if there is no posts , a list of docs
  static Future<dynamic> getPostsByUser(String userId) async {
    try {
      CollectionReference postsRef =
          FirebaseFirestore.instance.collection('posts');
      QuerySnapshot querySnapshot =
          await postsRef.where('userId', isEqualTo: userId).get();
      return querySnapshot.docs;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }


  static Future<Map<String, dynamic>?> getPostById(String postId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> postSnapshot =
          await FirebaseFirestore.instance
              .collection('posts')
              .doc(postId)
              .get();
      if (postSnapshot.exists) {
        Map<String, dynamic>? postData = postSnapshot.data();
        return postData;
      } else {
        return null;
      }
    } catch (error) {
      print('Error fetching post: $error');
      return null;
    }
  }



  static Future<List<Map<String, dynamic>>?> getFavoritePosts(
      String userId) async {
    try {
      //we get the user from the id first
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      Map<String, dynamic>? userData =
          userSnapshot.data() as Map<String, dynamic>?;

      //we ge the favposts ids and we get the posts having those ids as query snapshot
      List favPosts = userData?['favPosts'] ?? [];

      //if it's empty there is no need to fetch anything
      if (favPosts.isEmpty) {
        return [];
      }
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where(FieldPath.documentId, whereIn: favPosts)
          .get();

      //we turn that query snapshot to list of maps representing the post
      List<Map<String, dynamic>> posts = querySnapshot.docs.map((doc) {
        Map<String, dynamic> post = doc.data() as Map<String, dynamic>;
        //we addd the id to the map because we will need to visit the post (goToPost)
        post.addAll({'id': doc.id});
        return post;
      }).toList();
      return posts;
    } catch (error) {
      //if any error we return null
      print(error.toString());
      return null;
    }
  }

  static Future<List?> getFavoritePostsIds(String userId) async {
    try {
      //we get the user from the id first
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      Map<String, dynamic>? userData =
          userSnapshot.data() as Map<String, dynamic>?;
      return userData?['favPosts'];
    } catch (error) {
      return null;
    }
  }





  ////////////////////////////////////////////////////GET TAGS////////////////////////////////////////////////////////////


  //get all tags and return them as a list of maps, if error we return empty list
  static Future<List<Map<String, dynamic>>> getAllTags() async {
    List<Map<String, dynamic>> tagsList = [];

    try {
      CollectionReference tagsCollection = FirebaseFirestore.instance.collection('tags');
      QuerySnapshot querySnapshot = await tagsCollection.get();

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> tagData = doc.data() as Map<String, dynamic>;
        tagData['id'] = doc.id; // Add the document ID to the map
        tagsList.add(tagData);
      }

      return tagsList;
    } catch (e) {
      print('Error getting tags: $e');
      return [];
    }


  }








}
