// Dosya Yolu: /tools/portable/PortableBootstrap.java
// Amac: Windows portable OFBiz ilk calistirma guvenlik verilerini yerel olarak uretir
// Tool - Java
// Version: 1.2.0
// Aciklama: Java 8-17 ortak API tabaninda SecureRandom ile portable guvenlik ve runtime admin verilerini hazirlar
//
// Bagimli Oldugu Katman: Tool | Config

package org.turkuazlabs.ofbiz.portable;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;

public final class PortableBootstrap {
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final char[] PASSWORD_ALPHABET =
            "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789".toCharArray();
    private static final char[] SALT_ALPHABET =
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789".toCharArray();

    private PortableBootstrap() {
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 3 || !"init".equalsIgnoreCase(args[0])) {
            System.err.println("Usage: PortableBootstrap init <portable-root> <demo|runtime>");
            System.exit(2);
        }

        Path root = Paths.get(args[1]).toAbsolutePath().normalize();
        String mode = args[2].toLowerCase();

        if (!"demo".equals(mode) && !"runtime".equals(mode)) {
            throw new IllegalArgumentException("Unsupported portable mode: " + mode);
        }

        initialize(root, mode);
    }

    private static void initialize(Path root, String mode) throws Exception {
        Path dataDir = root.resolve("data");
        Path initialized = dataDir.resolve("security-initialized.flag");
        Files.createDirectories(dataDir);

        if (Files.exists(initialized)) {
            return;
        }

        String adminKey = randomBase64Url(48);
        String loginSecret = randomBase64(48);
        String tokenKey = randomBase64(48);

        writePrivateText(dataDir.resolve("admin-key.txt"), adminKey + System.lineSeparator());
        prepareSecurityOverride(root, loginSecret, tokenKey);

        if ("runtime".equals(mode)) {
            String password = randomPassword(32);
            String encodedPassword = encodeOfbizPassword(password);

            writePrivateText(
                    dataDir.resolve("initial-admin-password.txt"),
                    password + System.lineSeparator());
            writeAdminXml(dataDir.resolve("AdminUserLoginData.xml"), encodedPassword);
        } else {
            writePrivateText(
                    dataDir.resolve("initial-admin-password.txt"),
                    "ofbiz" + System.lineSeparator());
        }

        writePrivateText(
                initialized,
                "portable security initialized" + System.lineSeparator());
    }

    private static void prepareSecurityOverride(Path root, String loginSecret, String tokenKey)
            throws IOException {
        Path source = root.resolve("ofbiz")
                .resolve("framework")
                .resolve("security")
                .resolve("config")
                .resolve("security.properties");
        Path configDir = root.resolve("ofbiz").resolve("config");
        Path target = configDir.resolve("security.properties");

        if (!Files.isRegularFile(source)) {
            throw new IOException("source security.properties not found: " + source);
        }

        Files.createDirectories(configDir);
        Files.copy(source, target, StandardCopyOption.REPLACE_EXISTING);

        List<String> lines = new ArrayList<String>(Files.readAllLines(target, StandardCharsets.UTF_8));
        replaceProperty(lines, "login.secret_key_string", loginSecret);
        replaceProperty(lines, "security.token.key", tokenKey);
        Files.write(target, lines, StandardCharsets.UTF_8);
    }

    private static void replaceProperty(List<String> lines, String key, String value) {
        String prefix = key + "=";

        for (int index = 0; index < lines.size(); index++) {
            if (lines.get(index).startsWith(prefix)) {
                lines.set(index, prefix + value);
                return;
            }
        }

        lines.add(prefix + value);
    }

    private static String randomPassword(int length) {
        StringBuilder value = new StringBuilder(length);

        for (int index = 0; index < length; index++) {
            value.append(PASSWORD_ALPHABET[RANDOM.nextInt(PASSWORD_ALPHABET.length)]);
        }

        return value.toString();
    }

    private static String randomSalt(int length) {
        StringBuilder value = new StringBuilder(length);

        for (int index = 0; index < length; index++) {
            value.append(SALT_ALPHABET[RANDOM.nextInt(SALT_ALPHABET.length)]);
        }

        return value.toString();
    }

    private static String randomBase64(int byteCount) {
        byte[] bytes = new byte[byteCount];
        RANDOM.nextBytes(bytes);
        return Base64.getEncoder().encodeToString(bytes);
    }

    private static String randomBase64Url(int byteCount) {
        byte[] bytes = new byte[byteCount];
        RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private static String encodeOfbizPassword(String password)
            throws NoSuchAlgorithmException {
        String salt = randomSalt(16);
        MessageDigest sha1 = MessageDigest.getInstance("SHA-1");
        byte[] digest = sha1.digest((salt + password).getBytes(StandardCharsets.UTF_8));
        String encoded = Base64.getUrlEncoder().withoutPadding().encodeToString(digest);
        return "$SHA$" + salt + "$" + encoded;
    }

    private static void writeAdminXml(Path file, String encodedPassword)
            throws IOException {
        String lineSeparator = System.lineSeparator();
        String xml =
                "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" + lineSeparator
                + "<entity-engine-xml>" + lineSeparator
                + "    <UserLogin userLoginId=\"admin\" currentPassword=\""
                + encodedPassword
                + "\" requirePasswordChange=\"Y\"/>" + lineSeparator
                + "    <UserLoginSecurityGroup groupId=\"SUPER\" userLoginId=\"admin\" "
                + "fromDate=\"2001-01-01 12:00:00.0\"/>" + lineSeparator
                + "</entity-engine-xml>" + lineSeparator;

        writePrivateText(file, xml);
    }

    private static void writePrivateText(Path file, String content)
            throws IOException {
        Files.write(file, content.getBytes(StandardCharsets.UTF_8));
    }
}
