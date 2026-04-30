

import 'package:flutter/material.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {

  String? selectedCity;

  final cities = [
    {
      "name": "Mumbai",
      "image":
            "https://lh3.googleusercontent.com/aida-public/AB6AXuAXhqy6Wox8ahEiCJxXpnO_KvQmYSDsFbPfi6bytAICdJHiFMHbB7uFYL8P5yz2eSIeWKnM_vb0HZg3lFFpIoiOq5gw1TO9LJceeZV6wPvjdcCh666dYqPRBKVLs9gFK_Xxb7VotsQJ2LwvMHgjxY_B5LxuxYXIAvDghrnmwYmtZOmbdUqf9NqbQMyIiv4DrvxInXQTD6FI5SMy7kaiE5vuVoRBS5e2W9Q-k2kVhsbqFInmvAVUxj1JzY1uUaZg99SvKtk4SageFrQ"
    },
    {
      "name": "Delhi",
      "image":
            "https://lh3.googleusercontent.com/aida-public/AB6AXuBf4c8iqNtBdPxJWCsWIBy6lYgt1wrH3nbD2M6oM_wokL31yirzvmHJVaecg0eGqX0TYCKdQcff_BT-N7Io8rtAyp5AR3ta1xXa5KJayZEbZwOfHKtfgh0zl1_MyMDNT8qUvVwyrVqOvDecvfXfjjo1wwEY-BfYhVCV5pSjM-kHWHQVRgs9Bx8sDWo9KuZo1Z_6LyrtfKu2HpVg4jpeWI_BXNNMTuC953JsDz3AAC0f_nbRAV7edM6Wb2XK6nXazLlGY9x8mkpI5HM"
    },
    {
      "name": "Bangalore",
      "image":
            "https://lh3.googleusercontent.com/aida-public/AB6AXuCN_sd35h80CSUT2n89sHoodi2uJMyC6_-IdsdsOkC67R8WfxQg6N7o6zAEzVQyMl8bquxXq-P3wREKlj2IvJ7wwoApouIVFV5CagmV-PD5XCaeqS1ddD2r3drJWh_xc9qDwuvf8QF_MQ1mQdp_ZbYrd5ybuU3p_VYZrfQgo8MG4GkUPM5UBXF2robiSCeBxXu_PU65w1BMa8SfgADsW0hIa-WvybyNDa1gBn7YOBGykii84oWHnOimwxeW7uny9vDIE0O6dhgQJmU"
    },
    {
      "name": "Hyderabad",
      "image":
            "https://lh3.googleusercontent.com/aida-public/AB6AXuAAtKVTjRGL7zvjo0yD7ZGvbNHlji4UFCZyEjuHzix0Bi0GQe1Yr4M6Bq8U0sup07u8n3t9tVI2DO6-3mqoKGa-JiN9Z2tNBtqgsXUWeX7p44LBbEVHZaapC-Mlq0neZfI2dedqXMpX0DS7KS3YtCHGxlPHf2k2tASabU0u0b2f6LBXVn1j1PXGQ5WnGJDMr3aWhF21-uGae3XqFhc2HtV4ynGct6dTGJMQEUInINdJa6XC12ckR4IH_CxivC5HM8V9PWvBW4XqHeQ"
    },
  ];

  final branches = {
    "Mumbai": [
      {"name": "Borezy Bandra", "distance": "1.2 km"},
      {"name": "Borezy Andheri", "distance": "3.4 km"},
      {"name": "Borezy Powai", "distance": "5.1 km"},
    ],
    "Delhi": [
      {"name": "Borezy Connaught Place", "distance": "2.1 km"},
      {"name": "Borezy Saket", "distance": "4.8 km"},
    ],
    "Bangalore": [
      {"name": "Borezy Indiranagar", "distance": "1.5 km"},
      {"name": "Borezy Whitefield", "distance": "6.4 km"},
    ],
    "Hyderabad": [
      {"name": "Borezy Banjara Hills", "distance": "2.3 km"},
      {"name": "Borezy Gachibowli", "distance": "5.9 km"},
    ],
  };

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),

      body: SafeArea(
        child: SingleChildScrollView(

          padding: const EdgeInsets.symmetric(horizontal: 20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 10),

              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Icon(Icons.menu),
                  Text(
                    "BOREZY",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: Colors.purple,
                    ),
                  ),
                  Icon(Icons.shopping_bag_outlined)
                ],
              ),

              const SizedBox(height: 30),

              /// TITLE
              const Text(
                "Find your\nnearest branch",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Select your city to explore Borezy stores near you.",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 25),

              /// SEARCH
              Container(
                height: 55,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey),
                    SizedBox(width: 10),
                    Text(
                      "Search your city...",
                      style: TextStyle(color: Colors.grey),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 25),

              /// CITY GRID
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),

                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: .95,
                ),

                itemCount: cities.length,

                itemBuilder: (context, index) {

                  final city = cities[index];

                  return GestureDetector(

                    onTap: () {
                      setState(() {
                        selectedCity = city["name"] as String;
                      });
                    },

                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),

                      child: Stack(
                        fit: StackFit.expand,
                        children: [

                          Image.network(
                            city["image"] as String,
                            fit: BoxFit.cover,
                          ),

                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(.7),
                                  Colors.transparent
                                ],
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(16),

                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Text(
                                city["name"] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          )

                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 25),

              /// BRANCHES SECTION
              if (selectedCity != null) ...[

                Text(
                  "Branches in $selectedCity",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                ...branches[selectedCity]!.map((branch) {

                  return Container(

                    margin: const EdgeInsets.only(bottom: 14),

                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.05),
                          blurRadius: 10,
                        )
                      ],
                    ),

                    child: Row(
                      children: [

                        /// ICON
                        Container(
                          height: 45,
                          width: 45,
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.store,
                            color: Colors.purple,
                          ),
                        ),

                        const SizedBox(width: 14),

                        /// DETAILS
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Text(
                                branch["name"]!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              Text(
                                branch["distance"]!,
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        /// BUTTON
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),

                          onPressed: () {
                            /// Later open map screen
                          },

                          child: const Text("Explore"),
                        )

                      ],
                    ),
                  );
                }),

                const SizedBox(height: 20),
              ]

            ],
          ),
        ),
      ),
    );
  }
}