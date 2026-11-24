package ru.meefik.linuxdeploy.activity;

import android.graphics.Color;
import android.graphics.Typeface;
import android.os.Bundle;
import android.text.InputType;
import android.view.KeyEvent;
import android.view.inputmethod.EditorInfo;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.InputStreamReader;

import ru.meefik.linuxdeploy.PrefStore;

/**
 * Native command shell for the running container. Each command runs as root (su) through
 * assets/native/shell-run.sh (chroot). The working directory is kept between commands.
 */
public class ShellActivity extends AppCompatActivity {
    private TextView out;
    private ScrollView scroll;
    private EditText input;

    @Override
    public void onCreate(Bundle b) {
        super.onCreate(b);
        PrefStore.setLocale(this);
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(Color.BLACK);
        scroll = new ScrollView(this);
        out = new TextView(this);
        out.setTextColor(Color.rgb(200, 255, 200));
        out.setTypeface(Typeface.MONOSPACE);
        out.setTextSize(12);
        out.setTextIsSelectable(true);
        out.setPadding(16, 16, 16, 16);
        scroll.addView(out);
        input = new EditText(this);
        input.setHint("command (runs inside the container)");
        input.setTextColor(Color.WHITE);
        input.setHintTextColor(Color.GRAY);
        input.setTypeface(Typeface.MONOSPACE);
        input.setSingleLine(true);
        input.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS);
        input.setImeOptions(EditorInfo.IME_ACTION_SEND);
        input.setOnEditorActionListener((v, actionId, ev) -> {
            if (actionId == EditorInfo.IME_ACTION_SEND
                    || (ev != null && ev.getKeyCode() == KeyEvent.KEYCODE_ENTER)) {
                String cmd = input.getText().toString();
                input.setText("");
                if (!cmd.trim().isEmpty()) run(cmd);
                return true;
            }
            return false;
        });
        root.addView(scroll, new LinearLayout.LayoutParams(-1, 0, 1f));
        root.addView(input, new LinearLayout.LayoutParams(-1, -2));
        setContentView(root);
        setTitle("Shell");
        append("Container shell. Start the container first, then type commands.\n");
    }

    private void append(final String s) {
        runOnUiThread(() -> {
            out.append(s);
            scroll.post(() -> scroll.fullScroll(ScrollView.FOCUS_DOWN));
        });
    }

    private void run(final String cmd) {
        append("$ " + cmd + "\n");
        new Thread(() -> {
            try {
                File dir = new File(getFilesDir(), "native");
                try (FileOutputStream f = new FileOutputStream(new File(dir, "cmd.txt"))) {
                    f.write((cmd + "\n").getBytes("UTF-8"));
                }
                Process p = new ProcessBuilder("su").redirectErrorStream(true).start();
                try (DataOutputStream os = new DataOutputStream(p.getOutputStream())) {
                    os.writeBytes("sh " + dir + "/shell-run.sh '" + PrefStore.getUserName(this) + "'\n");
                    os.writeBytes("exit\n");
                    os.flush();
                }
                InputStream in = p.getInputStream();
                BufferedReader r = new BufferedReader(new InputStreamReader(in, "UTF-8"));
                String line;
                while ((line = r.readLine()) != null) append(line + "\n");
                p.waitFor();
            } catch (Exception e) {
                append("error: " + e.getMessage() + "\n");
            }
        }).start();
    }

    @Override
    public void setTheme(int resId) {
        super.setTheme(PrefStore.getTheme(this));
    }
}
