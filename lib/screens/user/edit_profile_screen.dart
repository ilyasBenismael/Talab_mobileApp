//first thing we set fields with old user data
//the user can pick img and date and change location fill fields
//then we can update the user

import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce/services/Utilities.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecommerce/services/UserService.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  List? location;
  DateTime? _selectedDate;
  bool _isImgEdited = false;
  dynamic _pickedImage;
  bool _isLoading = false;
  String? selectedCity;
  String _errorMsg = '';
  String? previousImgUrl;
  String locationMsg = '';
  bool isChef = false;
  late Future<int> stateVar;

  @override
  void initState() {
    super.initState();
    stateVar = setFields();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF282828),
          title: const Text('Edit profile'),
        ),
        body: FutureBuilder<int>(
          future: stateVar,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasData && snapshot.data == 1) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipOval(
                            child: _pickedImage != null
                                ? Container(
                                    child: _isImgEdited
                                        ? Image.file(
                                            _pickedImage!,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          )
                                        : CachedNetworkImage(
                                            imageUrl: _pickedImage!,
                                            placeholder: (context, url) =>
                                                Container(),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Container(),
                                            fit: BoxFit.cover,
                                            width: 100,
                                            height: 100,
                                          ),
                                  )
                                : Image.asset(
                                    'images/profileX.jpeg',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          IconButton(
                            onPressed: _pickImage,
                            icon: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      TextField(
                        controller: _cityController,
                        decoration: const InputDecoration(labelText: 'City'),
                      ),
                      TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                            labelText: 'description(optional)'),
                      ),
                      TextField(
                        controller: _dateController,
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        decoration: const InputDecoration(
                          labelText: 'Select Date',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                      SizedBox(height: 7),
                      isChef
                          ? Container(
                              padding: EdgeInsets.all(10),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      hintText: 'Enter phone number',
                                    ),
                                  ),
                                  TextField(
                                    onTap: () {
                                      getUserLocation();
                                    },
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      hintText: locationMsg,
                                      prefixIcon: const Icon(Icons.map),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: SaveUser,
                        child: const Text('Update User'),
                      ),
                      const SizedBox(height: 16),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : Container(),
                      Text(_errorMsg),
                    ],
                  ),
                ),
              );
            } else {
              return const Text('Error');
            }
          },
        ));
  }

  /////////////////////////////////////////////////// Set Fields ///////////////////////////////////////////////////////////////

  //this mthd is executed once at the beginning, and it's the only one accessing the statevar
  //we get user and initiate the textfieldControllers and if role==1 we set ischef to true and set chef fields
  //if all done very well we set statvar to 1 and rebuild, if any error we we set statevar to -1 and rebuild
  Future<int> setFields() async {
    try {
      DocumentSnapshot? documentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      if (documentSnapshot.exists) {
        Map<String, dynamic> userData =
            documentSnapshot.data() as Map<String, dynamic>;
        _nameController.text = userData['name'] ?? '';
        _cityController.text = userData['city'] ?? '';
        _descriptionController.text = userData['description'] ?? '';
        _selectedDate = userData['birthDay']?.toDate() ?? '';
        _dateController.text = _selectedDate.toString().substring(0, 10);
        _pickedImage = userData['imageUrl'];
        previousImgUrl = userData['imageUrl'];

        if (userData['role'] == 1) {
          isChef = true;
          location = userData['location'] ?? '';
          locationMsg = "lat: ${location?[0]}, long: ${location?[1]}";
          _phoneController.text = userData['phone'] ?? '';
        }
        return 1;
      } else {
        return -1;
      }
    } catch (e) {
      print(e.toString());
      return -1;
    }
  }

  /////////////////////////////////////////////////// Pick Image ///////////////////////////////////////////////////////////////

  //first pickedimage is neither null or has a network value (depends on if the user has profil pic or not)
  //if the image is picked successfully the picked image will have a file value and imageedited is true now
  Future<void> _pickImage() async {
    if (_isLoading) {
      return;
    }
    _isLoading = true;
    _pickedImage = await Utilities.pickImage();
    if (_pickedImage != null) {
      _isImgEdited = true;
    }
    _isLoading = false;
    setState(() {});
  }

  /////////////////////////////////////////////////// Pick Date ///////////////////////////////////////////////////////////////

  //we cant pick when it's loading, and if there is an error in picking we show it to user
  Future<void> _selectDate(BuildContext context) async {
    if (_isLoading) {
      return;
    }
    try {
      //when clicking the choose_date we make the show_date_picker object and the initial date will be the now date if no date is selected
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: _selectedDate ?? DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime(2100),
      );
      //if a new date is picked we update the ui with the new picked date
      //the selected_date is of type date but we show it as a string
      if (pickedDate != null && pickedDate != _selectedDate && mounted) {
        setState(() {
          _selectedDate = pickedDate;
          _dateController.text = _selectedDate!
              .toString()
              .substring(0, 10); // Update text field value
        });
      }
    } catch (e) {
      print('cant pick date: ' + e.toString());
    }
  }

  /////////////////////////////////////////////////// Get User Location ///////////////////////////////////////////////////////////////

  void getUserLocation() async {
    //if a previous update or getLocation are still running we leave
    if (_isLoading) {
      return;
    }

    //we make the loading ui
    _isLoading = true;
    locationMsg = "";

    //we get the location msg which is either a denial, an error or the location
    //we show the corresponding msg and leave
    //if it's a location we set the location list and leave
    List a = await UserService.getLocation();
    if (a[0] == -1) {
      _isLoading = false;
      toastMsg("u have to permit location access");
    } else if (a[0] == -2) {
      _isLoading = false;
      toastMsg("error while getting user location");
    } else {
      location = a;
      _isLoading = false;
      locationMsg = "lat: ${a[0]}, long: ${a[1]}";
      toastMsg("location successfully updated");
    }
    setState(() {});
  }

/////////////////////////////////////////////////// Save User ///////////////////////////////////////////////////////////////

  void SaveUser() {
    //if it's still loading from previous update we return
    if (_isLoading) {
      return;
    }

    //first thing we make the ui of a loading page
    _errorMsg = '';
    _isLoading = true;
    setState(() {});

    //we get userinfos from controllers and put chef fields to null cuz we might need it in the update methode if the user is not a chef
    final name = _nameController.text.trim();
    final city = _cityController.text.trim();
    final description = _descriptionController.text.trim();
    Map<String, dynamic> userInfo = {
      'name': name,
      'city': city,
      'description': description,
      'imageFile': _pickedImage,
      'birthDay': _selectedDate,
      'phone': null,
      'location': null
    };

    //we check if the infos are not empty (if they are then we show the errorMsg and return)
    if (userInfo['name'].isEmpty ||
        userInfo['city'].isEmpty ||
        userInfo['birthDay'] == null) {
      _errorMsg = 'fill all fields';
      _isLoading = false;
      setState(() {});
      return;
    }

    //if it's a chef we update chef fields and check their emptiness
    if (isChef) {
      userInfo['location'] = location;
      userInfo['phone'] = _phoneController.text.trim();

      if (userInfo['phone'].isEmpty || location == null) {
        _errorMsg = 'fill all fields';
        _isLoading = false;
        setState(() {});
        return;
      }
    }

    //we update the user, if there is an error we show it and return, if it's okey we go to previous page
    UserService.updateUser(userInfo, _isImgEdited, previousImgUrl)
        .then((result) {
      _isLoading = false;
      if (result == 1) {
        Navigator.pop(context);
      } else {
        _errorMsg = result.toString();
      }
      setState(() {});
    });
  }

  /////////////////////////////////////////////////// Toast ///////////////////////////////////////////////////////////////

  toastMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
