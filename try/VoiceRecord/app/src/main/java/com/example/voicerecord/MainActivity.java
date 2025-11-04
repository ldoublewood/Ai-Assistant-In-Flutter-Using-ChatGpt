package com.example.voicerecord;

import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import android.Manifest;
import android.content.pm.PackageManager;
import android.media.MediaPlayer;
import android.media.MediaRecorder;
import android.os.Bundle;
import android.os.Environment;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;

import java.io.File;
import java.io.IOException;

public class MainActivity extends AppCompatActivity {

    private static final int REQUEST_RECORD_AUDIO_PERMISSION = 200;
    private MediaRecorder mediaRecorder;
    private MediaPlayer mediaPlayer;
    private String audioFilePath;
    private boolean isRecording = false;
    private boolean isPlaying = false;

    private Button btnRecord;
    private Button btnPlay;
    private Button btnStop;
    private TextView tvStatus;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // 初始化UI组件
        initViews();
        
        // 设置音频文件路径
        setupAudioFilePath();
        
        // 检查权限
        checkPermissions();
        
        // 设置按钮点击事件
        setupClickListeners();
    }

    private void initViews() {
        btnRecord = findViewById(R.id.btn_record);
        btnPlay = findViewById(R.id.btn_play);
        btnStop = findViewById(R.id.btn_stop);
        tvStatus = findViewById(R.id.tv_status);
        
        // 初始状态
        btnPlay.setEnabled(false);
        btnStop.setEnabled(false);
        tvStatus.setText("准备就绪");
    }

    private void setupAudioFilePath() {
        // 设置音频文件保存路径
        File audioDir = new File(getExternalFilesDir(Environment.DIRECTORY_MUSIC), "VoiceRecord");
        if (!audioDir.exists()) {
            audioDir.mkdirs();
        }
        audioFilePath = audioDir.getAbsolutePath() + "/recording.3gp";
    }

    private void checkPermissions() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) 
                != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this,
                    new String[]{Manifest.permission.RECORD_AUDIO,
                            Manifest.permission.WRITE_EXTERNAL_STORAGE},
                    REQUEST_RECORD_AUDIO_PERMISSION);
        }
    }

    private void setupClickListeners() {
        btnRecord.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (!isRecording) {
                    startRecording();
                } else {
                    stopRecording();
                }
            }
        });

        btnPlay.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (!isPlaying) {
                    startPlaying();
                } else {
                    stopPlaying();
                }
            }
        });

        btnStop.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (isRecording) {
                    stopRecording();
                } else if (isPlaying) {
                    stopPlaying();
                }
            }
        });
    }

    private void startRecording() {
        try {
            // 创建MediaRecorder实例
            mediaRecorder = new MediaRecorder();
            mediaRecorder.setAudioSource(MediaRecorder.AudioSource.MIC);
            mediaRecorder.setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP);
            mediaRecorder.setOutputFile(audioFilePath);
            mediaRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB);

            mediaRecorder.prepare();
            mediaRecorder.start();

            isRecording = true;
            btnRecord.setText("停止录音");
            btnPlay.setEnabled(false);
            btnStop.setEnabled(true);
            tvStatus.setText("正在录音...");

            Toast.makeText(this, "开始录音", Toast.LENGTH_SHORT).show();

        } catch (IOException e) {
            e.printStackTrace();
            Toast.makeText(this, "录音失败: " + e.getMessage(), Toast.LENGTH_SHORT).show();
        }
    }

    private void stopRecording() {
        if (mediaRecorder != null) {
            try {
                mediaRecorder.stop();
                mediaRecorder.release();
                mediaRecorder = null;

                isRecording = false;
                btnRecord.setText("开始录音");
                btnPlay.setEnabled(true);
                btnStop.setEnabled(false);
                tvStatus.setText("录音完成");

                Toast.makeText(this, "录音已保存", Toast.LENGTH_SHORT).show();

            } catch (RuntimeException e) {
                e.printStackTrace();
                Toast.makeText(this, "停止录音失败", Toast.LENGTH_SHORT).show();
            }
        }
    }

    private void startPlaying() {
        try {
            mediaPlayer = new MediaPlayer();
            mediaPlayer.setDataSource(audioFilePath);
            mediaPlayer.prepare();
            mediaPlayer.start();

            isPlaying = true;
            btnPlay.setText("停止播放");
            btnRecord.setEnabled(false);
            btnStop.setEnabled(true);
            tvStatus.setText("正在播放...");

            // 播放完成监听
            mediaPlayer.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
                @Override
                public void onCompletion(MediaPlayer mp) {
                    stopPlaying();
                }
            });

            Toast.makeText(this, "开始播放", Toast.LENGTH_SHORT).show();

        } catch (IOException e) {
            e.printStackTrace();
            Toast.makeText(this, "播放失败: " + e.getMessage(), Toast.LENGTH_SHORT).show();
        }
    }

    private void stopPlaying() {
        if (mediaPlayer != null) {
            mediaPlayer.release();
            mediaPlayer = null;

            isPlaying = false;
            btnPlay.setText("播放录音");
            btnRecord.setEnabled(true);
            btnStop.setEnabled(false);
            tvStatus.setText("播放完成");

            Toast.makeText(this, "播放停止", Toast.LENGTH_SHORT).show();
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        
        if (requestCode == REQUEST_RECORD_AUDIO_PERMISSION) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                Toast.makeText(this, "录音权限已获取", Toast.LENGTH_SHORT).show();
            } else {
                Toast.makeText(this, "需要录音权限才能使用此功能", Toast.LENGTH_LONG).show();
                finish();
            }
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        
        // 释放资源
        if (mediaRecorder != null) {
            mediaRecorder.release();
            mediaRecorder = null;
        }
        
        if (mediaPlayer != null) {
            mediaPlayer.release();
            mediaPlayer = null;
        }
    }
}