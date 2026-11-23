
import java.util.Random;
/**
 * Génère un journal d'accès d'API back-end, propre à chaque étudiant.
 * Usage : java -cp out GenerateurLogs <matricule> <nombreDeLignes>
 */
public class GenerateurLogs {
    static final String[] ENDPOINTS = {
        "/api/etudiants", "/api/etudiants/", "/api/notes", "/api/cours",
        "/api/auth/login", "/api/paiements", "/api/health"
    };
    public static void main(String[] args) {
        if (args.length != 2) {
            System.err.println("Usage : java -cp out GenerateurLogs <matricule> <nombreDeLignes>");
            System.exit(1);
        }
        int n;
        try {
            n = Integer.parseInt(args[1]);
        } catch (NumberFormatException e) {
            System.err.println("Erreur : le nombre de lignes doit être un entier");
            System.exit(2);
            return;
        }
        Random r = new Random(args[0].hashCode());
        String suspecte = "197.149." + r.nextInt(256) + "." + (1 + r.nextInt(254));
        int seconde = 8 * 3600;
        for (int i = 0; i < n; i++) {
            seconde += 1 + r.nextInt(12);
            boolean attaque = r.nextInt(100) < 6;
            String ip = attaque ? suspecte : "10.0." + r.nextInt(4) + "." + (10 + r.nextInt(15));
            String chemin = attaque ? "/api/auth/login" : ENDPOINTS[r.nextInt(ENDPOINTS.length)];
            String methode = "GET";
            int statut = 200;
            int duree = 5 + r.nextInt(300);
            switch (chemin) {
                case "/api/etudiants/":
                    chemin += (1 + r.nextInt(120));
                    statut = r.nextInt(100) < 15 ? 404 : 200;
                    break;
                case "/api/notes":
                    chemin += "?page=" + (1 + r.nextInt(5));
                    statut = r.nextInt(100) < 8 ? 400 : 200;
                    break;
                case "/api/auth/login":
                    methode = "POST";
                    statut = attaque ? 401 : (r.nextInt(100) < 20 ? 401 : 200);
                    break;
                case "/api/paiements":
                    methode = r.nextBoolean() ? "POST" : "GET";
                    int t = r.nextInt(100);
                    statut = t < 6 ? 500 : (t < 10 ? 503 : (methode.equals("POST") ? 201 : 200));
                    if (r.nextInt(100) < 5) {
                        duree = 1500 + r.nextInt(1500);
                    }
                    break;
                default:
                    break;
            }
            int octets = statut >= 400 ? 60 + r.nextInt(100) : 200 + r.nextInt(4000);
            System.out.printf("%s - - [23/Nov/2026:%02d:%02d:%02d +0000] \"%s %s HTTP/1.1\" %d %d %dms%n",
                ip, seconde / 3600, (seconde / 60) % 60, seconde % 60, methode, chemin,
                statut, octets, duree);
        }
    }
}
