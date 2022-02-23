import 'dart:core';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' show basename, join;
import 'package:http/http.dart' as http;

void main(List<String> args) async {
  if (args.length < 6) {
    if (args.length == 1) {
      if (args[0] == 'clean') {
        clean();
        exit(1);
      } else if (args[0] == 'refreshutils') {
        await refreshUtils();
        exit(1);
      } else {
        print('Usage: dart gen.dart <mc_version> <plugin_name> <package_name> <mainclass_name> <author_name> <outdir>');
        exit(1);
      }
    }
    print('Usage: dart gen.dart <mc_version> <plugin_name> <package_name> <mainclass_name> <author_name> <outdir>');
    exit(1);
  }

  final mcVersion = args[0];
  String pluginName = args[1];
  String packageName = args[2];
  String mainClassName = args[3];
  String authorName = args[4];
  String outDir = args[5];

  print('Cleanup...');
  clean();
  print('Generating plugin for Minecraft $mcVersion');
  print('Plugin name: $pluginName');
  print('Package name: $packageName');
  print('Main class name: $mainClassName');
  print('Author name: $authorName');

  print("Generating plugin '$pluginName' for package '$packageName'");
  var mainDir = await Directory('src/main/java/net/kunmc/lab/${packageName.replaceAll('.', '/')}').create(recursive: true);
  var resourceDir = await Directory('src/main/resources/').create(recursive: true);

  print("Generating main class '$mainClassName'");
  var mainFile = await File('${mainDir.path}/${mainClassName}.java').create(recursive: true);

  await mainFile.writeAsString('''
package net.kunmc.lab.${packageName};

import org.bukkit.plugin.java.JavaPlugin;

public final class ${mainClassName} extends JavaPlugin {

    @Override
    public void onEnable() {
        getLogger().info("${pluginName} has been enabled!");
    }

    @Override
    public void onDisable() {
        getLogger().info("${pluginName} has been disabled!");
    }

}''');

  print("Generating plugin.yml");
  var pluginYml = await File('${resourceDir.path}/plugin.yml').create(recursive: true);

  await pluginYml.writeAsString('''
name: ${pluginName}
version: \'\${project.version}\'
main: net.kunmc.lab.${packageName}.${mainClassName}
api-version: ${mcVersion}
prefix: ${pluginName}
author: ${authorName}''');

  print("Generating pom.xml");
  var pomXml = await File('pom.xml').create(recursive: true);
  var paperUrl = await getPaperUrl(mcVersion);
  
  // write pom.xml
  await pomXml.writeAsString('''
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>net.kunmc.lab</groupId>
    <artifactId>${packageName}</artifactId>
    <version>1.0</version>
    <packaging>jar</packaging>
    <name>${pluginName}</name>
    <properties>
        <java.version>1.8</java.version>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>
    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.8.1</version>
                <configuration>
                    <source>\${java.version}</source>
                    <target>\${java.version}</target>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-shade-plugin</artifactId>
                <version>3.2.4</version>
                <executions>
                    <execution>
                        <phase>package</phase>
                        <goals>
                            <goal>shade</goal>
                        </goals>
                        <configuration>
                            <createDependencyReducedPom>false</createDependencyReducedPom>
                        </configuration>
                    </execution>
                </executions>
            </plugin>
            <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-dependency-plugin</artifactId>
            <executions>
                <execution>
                    <id>copy-installed</id>
                    <phase>install</phase>
                    <goals>
                        <goal>copy</goal>
                    </goals>
                    <configuration>
                        <artifactItems>
                            <artifactItem>
                                <groupId>\${project.groupId}</groupId>
                                <artifactId>\${project.artifactId}</artifactId>
                                <version>\${project.version}</version>
                                <type>\${project.packaging}</type>
                            </artifactItem>
                        </artifactItems>
                        <outputDirectory>${outDir}</outputDirectory>
                    </configuration>
                </execution>
            </executions>
        </plugin>
        </plugins>
        <resources>
            <resource>
                <directory>src/main/resources</directory>
                <filtering>true</filtering>
            </resource>
        </resources>
    </build>
    <repositories>
        <repository>
            <id>papermc-repo</id>
            <url>https://papermc.io/repo/repository/maven-public/</url>
        </repository>
        <repository>
            <id>sonatype</id>
            <url>https://oss.sonatype.org/content/groups/public/</url>
        </repository>
    </repositories>
    <dependencies>
        <dependency>
            <groupId>com.destroystokyo.paper</groupId>
            <artifactId>paper-api</artifactId>
            <version>${paperUrl}</version>
            <scope>provided</scope>
        </dependency>
    </dependencies>
</project>''');

  print("Generating LICENSE");
  var licenseFile = await File('LICENSE').create(recursive: true);
  final date = DateTime.now();
  final year = date.year;

  await licenseFile.writeAsString('''
MIT License

Copyright (c) ${year} KUN Lab, ${authorName}

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.''');

  print("Generating .gitignore");
  var gitignore = await File('.gitignore').create(recursive: true);
  await gitignore.writeAsString('''
*.class
*.log
*.ctxt
.mtj.tmp/
*.jar
*.war
*.nar
*.ear
*.zip
*.tar.gz
*.rar
*.iml
*.idea/
*.idea/*.xml
hs_err_pid*
.idea/
.packages
.pubspec.lock
.dart_tool/
.dart_tool/build/
.dart_tool/pubspec.lock
.dart_tool/package_config.json
.dart_tool/package_config.json.sum''');

  print("Generating README.md");
  var readme = await File('README.md').create(recursive: true);
  await readme.writeAsString('''
# ${pluginName}  

## Description  

plugin description write here  

## Usage  

usage write here  

## License  

MIT License  

## Author  

${authorName}  ''');

  print("Checking generate files");
  check('pom.xml');
  check('LICENSE');
  check('.gitignore');
  check('README.md');

  check("src/main/java/net/kunmc/lab/${packageName}");
  check("src/main/java/net/kunmc/lab/${packageName}/${mainClassName}.java");
  check("src/main/resources/");
  check("src/main/resources/plugin.yml");

  print("Good Bye!");

}

Future<void> refreshUtils() async {
  var files = Directory.current.listSync(recursive: true, followLinks: false);
  bool next = false;
  String path = "";
  String package = "";
  for (var file in files) {
    if (basename(file.path) == 'lab') {
      next = true;
      continue;
    }
    if (next) {
      path = file.path;
      package = basename(file.path);
      break;
    }
  }

  if (package == "" || path == "") {
    print("Error: lab folder not found");
    return;
  }

  print("Refresh Utils");
  files = Directory(path).listSync(recursive: false, followLinks: false);
  bool found = false;
  for (var file in files) {
    if (basename(file.path) == 'Utils.java') {
      found = true;
      print("Found Utils.java");
      file.deleteSync();
      Uri url = Uri.parse('https://raw.githubusercontent.com/Kei-7777/wdg-UtilsPackage/main/Utils.java');
      var request = await http.get(url);
      var utils = await File(file.path).create(recursive: true);
      await utils.writeAsString(request.body);

      var content = await utils.readAsString();
      content = content.replaceAll('%package%', package);
      await utils.writeAsString(content);
      break;
    }
  }

  if (!found) {
    /*
    print("Not found Utils.java");
    Uri url = Uri.parse('https://raw.githubusercontent.com/Kei-7777/wdg-UtilsPackage/main/Utils.java');
    print("Downloading Utils.java");
    var request = await http.read(url);
    print("Downloaded Utils.java");
    path = join(path, 'Utils.java');
    var utils = await File(path).create(recursive: true);
    await utils.writeAsString(request);
    print(request);
    */

    path = join(path, 'Utils.java');
    var utils = await File(path).create(recursive: false);
    var request = await HttpClient().getUrl(Uri.parse('https://raw.githubusercontent.com/Kei-7777/wdg-UtilsPackage/main/Utils.java'));
    var response = await request.close();
    var responseBodyText = await utf8.decodeStream(response);

    await utils.writeAsString(responseBodyText);
    print(responseBodyText);

    var content = await utils.readAsString();
    content = content.replaceAll('%package%', package);
    await utils.writeAsString(content);
  }

  print("Refresh Utils.java");
  exit(1);
}

void clean() {
  var files = Directory.current.listSync(recursive: false, followLinks: false);
  for (var file in files) {
    print(file.path);
    if (file is File && 
    basename(file.path) != 'gen.dart' && 
    basename(file.path) != 'gen.dart.snapshot' && 
    basename(file.path) != 'pubspec.yaml' &&
    basename(file.path) != 'generate.bat') {
      file.deleteSync();
      print("Delete ${file.path}");
    } else {
      if (file is Directory) {
        file.deleteSync(recursive: true);
        print("Delete ${file.path}");
      }
    }
  }
  print("Good Bye!");
}

check(String path) {
  if (FileSystemEntity.isDirectorySync(path)) {
    print("$path is exist");
  } else {
    if (FileSystemEntity.isFileSync(path)) {
      print("$path is exist");
    } else {
      print("$path is not exist");
    }
  }
}

getPaperUrl(String mcVersion) {
  switch (mcVersion) {
    case "1.9.4":
      return "1.9.4-R0.1-SNAPSHOT";
    case "1.10.2":
      return "1.10.2-R0.1-SNAPSHOT";
    case "1.11":
      return "1.11-R0.1-SNAPSHOT";
    case "1.11.1":
      return "1.11.1-R0.1-SNAPSHOT";
    case "1.11.2":
      return "1.11.2-R0.1-SNAPSHOT";
    case "1.12":
      return "1.12-R0.1-SNAPSHOT";
    case "1.12.1":
      return "1.12.1-R0.1-SNAPSHOT";
    case "1.12.2":
      return "1.12.2-R0.1-SNAPSHOT";
    case "1.13-pre7":
      return "1.13-pre7-R0.1-SNAPSHOT";
    case "1.13":
      return "1.13-R0.1-SNAPSHOT";
    case "1.13.1":
      return "1.13.1-R0.1-SNAPSHOT";
    case "1.13.2":
      return "1.13.2-R0.1-SNAPSHOT";
    case "1.14":
      return "1.14-R0.1-SNAPSHOT";
    case "1.14.1":
      return "1.14.1-R0.1-SNAPSHOT";
    case "1.14.2":
      return "1.14.2-R0.1-SNAPSHOT";
    case "1.14.3":
      return "1.14.3-R0.1-SNAPSHOT";
    case "1.14.4":
      return "1.14.4-R0.1-SNAPSHOT";
    case "1.15":
      return "1.15-R0.1-SNAPSHOT";
    case "1.15.1":
      return "1.15.1-R0.1-SNAPSHOT";
    case "1.15.2":
      return "1.15.2-R0.1-SNAPSHOT";
    case "1.16.1":
      return "1.16.1-R0.1-SNAPSHOT";
    case "1.16.2":
      return "1.16.2-R0.1-SNAPSHOT";
    case "1.16.3":
      return "1.16.3-R0.1-SNAPSHOT";
    case "1.16.4":
      return "1.16.4-R0.1-SNAPSHOT";
    case "1.16.5":
      return "1.16.5-R0.1-SNAPSHOT";
  }
}
