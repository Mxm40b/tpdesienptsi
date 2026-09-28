import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:freedesktop_desktop_entry/freedesktop_desktop_entry.dart';
import 'package:win32audio/win32audio.dart';

import 'dart:io';
import 'dart:typed_data';

void main() {
  // TODO: dé-commenter les lignes dessous pour blocker l'accès en dehors des heures de TP
  // final now = DateTime.now();
  // if (now.weekday != 2 || now.hour > 19 || now.hour < 13) {
  //   runApp(const BlockedApp());
  // } else {
  programs.sort((a, b) => a.name.compareTo(b.name));
  runApp(const MainApp());
  // }
}

class BlockedApp extends StatelessWidget {
  const BlockedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Text("Now is not the time!"));
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'L\'application de Mr Bernard pour les TP réécrite en flutter',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints.expand(),
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            // main elements
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 10),
              FractionallySizedBox(
                widthFactor: 0.8,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    color: Color.fromARGB(255, 150, 0, 150),
                  ),
                  padding: EdgeInsets.all(2),
                  child: RawMaterialButton(
                    elevation: 0,
                    padding: EdgeInsetsGeometry.all(10),
                    onPressed: () {
                      Process.start('sioyek', ['/home/mxmfrpr/lesTP.pdf']);
                      // TODO: sous windows, dé-commenter ceci:
                      // Process.start('cmd.exe', [
                      //   '/c',
                      //   'start',
                      //   '',
                      //   pdfPath,
                      // ], runInShell: false);
                    },
                    child: Text(
                      "Le PDF des TP",
                      style: TextStyle(fontSize: 40.0, color: Colors.white),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              // GridView.count(
              //   crossAxisCount: 5,
              //   primary: false,
              //   shrinkWrap: true,
              //   physics: const NeverScrollableScrollPhysics(),
              //   children: programs.map(programButton).toList(),
              // ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 120,
                  childAspectRatio: 1,
                ),
                itemCount: programs.length,
                itemBuilder: (context, index) {
                  return programButton(programs[index]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProgramButtonLayout extends StatelessWidget {
  final Widget image;
  final Program program;
  const ProgramButtonLayout({
    super.key,
    required this.image,
    required this.program,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RawMaterialButton(
          onPressed: () {
            if (Platform.isLinux) {
              Process.start('sh', ['-c', '${program.path}${program.name}']);
            } else if (Platform.isWindows) {
              Process.start(
                '${program.path}${program.name}',
                [],
                runInShell: false,
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 1.0),
            child: Column(
              children: [image, SizedBox(height: 5), Text(program.name)],
            ),
          ),
        ),
      ],
    );
  }
}

Widget iconWidget(File file) {
  if (file.path.toLowerCase().endsWith('.svg')) {
    return SvgPicture.file(file, width: 64, height: 64);
  }
  return Image.file(file, width: 64, height: 64);
}

Widget? programButton(Program program) {
  final themes = FreedesktopIconThemes();
  if (Platform.isLinux) {
    return FutureBuilder<File?>(
      future: themes.findIcon(
        IconQuery(
          name: (program.icon == null) ? program.name.trim() : program.icon!,
          size: 64,
          scale: 1,
          extensions: ['png', 'svg'],
        ),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // return const SizedBox(
          //   width: 50,
          //   height: 50,
          //   child: CircularProgressIndicator(),
          // );
          return ProgramButtonLayout(
            image: SizedBox.square(
              dimension: 64,
              child: CircularProgressIndicator(),
            ),
            program: program,
          );
        }

        final file = snapshot.data;

        return ProgramButtonLayout(
          image: file != null
              ? iconWidget(file)
              : const Icon(Icons.apps, size: 64, color: Colors.deepPurple),
          program: program,
        );
      },
    );
  } else if (Platform.isWindows) {
    return FutureBuilder<Uint8List?>(
      future: getExeIcon('${program.path}${program.name}'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // return const SizedBox(
          //   width: 50,
          //   height: 50,
          //   child: CircularProgressIndicator(),
          // );
          return ProgramButtonLayout(
            image: SizedBox.square(
              dimension: 64,
              child: CircularProgressIndicator(),
            ),
            program: program,
          );
        }

        final iconBytes = snapshot.data;

        return ProgramButtonLayout(
          image: iconBytes != null
              ? Image.memory(iconBytes, width: 64, height: 64)
              : const Icon(Icons.apps, size: 64, color: Colors.deepPurple),
          program: program,
        );
      },
    );
  }
  return null;
}

Future<Uint8List?> getExeIcon(String exePath) async {
  return WinIcons().extractFileIcon(exePath);
}

class Program {
  String name = "No name";
  String path = "";
  String? icon;
  Program(this.path, this.name, {this.icon});
}

// TODO: sous Windows, rajouter les paths, eg "C:\Path\To\Win executables\" puis "app\ name.exe"
// et retirer ceux-ci
List<Program> programs =
    groupPrograms("/usr/bin/env ", ["zen", " firefox"]) +
    groupPrograms("/usr/bin/env ", ["zen", " firefox"]) +
    groupPrograms("/usr/bin/env ", [
      "zen-browser",
      " firefox",
      "signal-desktop",
      "bitwarden",
      "feishin",
      "blender",
      "tauon",
    ]) +
    groupProgramsIconed("/usr/bin/env ", [
      ("nautilus", "org.gnome.Nautilus"),
      ("reaper", "cockos-reaper"),
      ("steam-asahi", "steam"),
    ]);

List<Program> groupPrograms(String path, List<String> names) {
  final List<Program> programs = [];
  for (int nameI = 0; nameI < names.length; nameI++) {
    programs.add(Program(path, names.elementAt(nameI)));
  }
  return programs;
}

List<Program> groupProgramsIconed(String path, List<(String, String)> names) {
  final List<Program> programs = [];
  for (int nameI = 0; nameI < names.length; nameI++) {
    programs.add(
      Program(path, names.elementAt(nameI).$1, icon: names.elementAt(nameI).$2),
    );
  }
  return programs;
}
