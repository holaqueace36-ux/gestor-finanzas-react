import React, { useState } from 'react';
import { SafeAreaView, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';
import { useUser } from './_layout';

export default function ProfileScreen() {
  const { userData, setUserData } = useUser();
  const [nombre, setNombre] = useState('');
  const [ocupacion, setOcupacion] = useState('');
  const [monto, setMonto] = useState('');

  const iniciar = () => {
    setUserData({
      nombre,
      ocupacion,
      monto: monto || '0',
      inicializado: true
    });
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.content}>
        <Text style={styles.titulo}>Configura tu Perfil</Text>

        <View style={styles.inputGroup}>
          <Text style={styles.label}>Tu Nombre</Text>
          <TextInput 
            placeholder="" // <-- AQUÍ: Antes decía "Ej. Juan Prieto", ahora está vacío
            style={styles.input} 
            value={nombre} 
            onChangeText={setNombre} 
          />
        </View>

        <View style={styles.inputGroup}>
          <Text style={styles.label}>Tu Ocupación</Text>
          <TextInput 
            placeholder="" // <-- AQUÍ: Antes decía "Ej. Estudiante", ahora está vacío
            style={styles.input} 
            value={ocupacion} 
            onChangeText={setOcupacion} 
          />
        </View>

        <View style={styles.inputGroup}>
          <Text style={styles.label}>Presupuesto Inicial ($)</Text>
          <TextInput 
            placeholder="" 
            style={styles.input} 
            keyboardType="numeric" 
            value={monto} 
            onChangeText={setMonto} 
          />
        </View>

        <TouchableOpacity style={styles.btn} onPress={iniciar}>
          <Text style={styles.btnTxt}>Empezar ahora</Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  content: { padding: 30, flex: 1, justifyContent: 'center' },
  titulo: { fontSize: 26, fontWeight: 'bold', marginBottom: 40, color: '#333' },
  inputGroup: { marginBottom: 25 },
  label: { fontSize: 14, color: '#888', marginBottom: 5, fontWeight: '600' },
  input: { borderBottomWidth: 2, borderBottomColor: '#eee', fontSize: 18, paddingVertical: 8, color: '#333' },
  btn: { backgroundColor: '#007AFF', padding: 18, borderRadius: 15, alignItems: 'center', marginTop: 30 },
  btnTxt: { color: '#fff', fontWeight: 'bold', fontSize: 16 }
});