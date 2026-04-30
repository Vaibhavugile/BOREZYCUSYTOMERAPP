import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_screen.dart';

class CitySelectionScreen extends StatefulWidget {
  const CitySelectionScreen({super.key});

  @override
  State<CitySelectionScreen> createState() => _CitySelectionScreenState();
}

class _CitySelectionScreenState extends State<CitySelectionScreen>
    with TickerProviderStateMixin {

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

  Future<void> selectCity(String city) async {

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("selectedCity", city);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const MainScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 40),

              const Text(
                "Choose your\ncity",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Select your city to explore Borezy stores near you.",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 25),

              /// SEARCH BAR
              Container(
                height: 55,
                padding: const EdgeInsets.symmetric(horizontal: 16),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.05),
                      blurRadius: 10,
                    )
                  ],
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

              const SizedBox(height: 30),

              /// CITY GRID
              Expanded(
                child: GridView.builder(

                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: .95,
                  ),

                  itemCount: cities.length,

                  itemBuilder: (context, index) {

                    final city = cities[index];

                    return GestureDetector(

                      onTap: () => selectCity(city["name"] as String),

                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),

                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.08),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),

                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),

                          child: Stack(
                            fit: StackFit.expand,
                            children: [

                              Hero(
                                tag: city["name"]!,
                                child: Image.network(
                                  city["image"]!,
                                  fit: BoxFit.cover,
                                ),
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
                                    city["name"]!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )

                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10)

            ],
          ),
        ),
      ),
    );
  }
}