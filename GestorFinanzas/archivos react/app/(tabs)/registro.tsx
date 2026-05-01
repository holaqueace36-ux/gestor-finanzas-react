import { useRouter } from 'expo-router';
import React, { useState } from 'react';
import { Alert, SafeAreaView, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';
import { useUser } from './_layout';

interface Movimiento {
  id: string;
  nombre: string;
  monto: number;
  tipo: 'ingreso' | 'gasto';
  fecha: string;
}

export default function RegistroScreen() {
  const router = useRouter();
  const { userData, gastos, setGastos } = useUser();
  const [nombre, setNombre] = useState('');
  const [monto, setMonto] = useState('');
  const [tipo, setTipo] = useState<'ingreso' | 'gasto'>('gasto'); 

  const guardar = () => {
    if (!nombre || !monto) return Alert.alert("Campos vacios", "Por favor registra una descripcion y un valor.");

    const valor = parseFloat(monto);
    
    const ingresos = gastos
      .filter((i: Movimiento) => i.tipo === 'ingreso')
      .reduce((a: number, b: Movimiento) => a + b.monto, 0);
    const egresos = gastos
      .filter((i: Movimiento) => i.tipo === 'gasto')
      .reduce((a: number, b: Movimiento) => a + b.monto, 0);

    const disponible = parseFloat(userData.monto) + ingresos - egresos;

    if (tipo === 'gasto' && valor > disponible) {
      return Alert.alert("Saldo Insuficiente", `Tu saldo disponible es de $${disponible.toLocaleString()}`);
    }

    const nuevo: Movimiento = {
      id: Date.now().toString(),
      nombre,
      monto: valor,
      tipo,
      fecha: new Date().toLocaleDateString()
    };

    setGastos([nuevo, ...gastos]);
    router.replace('/');
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.content}>
        <Text style={styles.titulo}>Nueva Transaccion</Text>
        
        <Text style={styles.label}>Tipo de movimiento</Text>
        <View style={styles.selector}>
          <TouchableOpacity 
            onPress={() => setTipo('gasto')} 
            style={[styles.opt, tipo === 'gasto' && {backgroundColor: '#ff4d4d'}]}
          >
            <Text style={[styles.optTxt, tipo === 'gasto' && {color: '#fff'}]}>Gasto</Text>
          </TouchableOpacity>
          <TouchableOpacity 
            onPress={() => setTipo('ingreso')} 
            style={[styles.opt, tipo === 'ingreso' && {backgroundColor: '#2ecc71'}]}
          >
            <Text style={[styles.optTxt, tipo === 'ingreso' && {color: '#fff'}]}>Ingreso</Text>
          </TouchableOpacity>
        </View>

        <View style={styles.inputGroup}>
          <Text style={styles.label}>Descripcion</Text>
          <TextInput 
            placeholder="" 
            style={styles.input} 
            value={nombre} 
            onChangeText={setNombre} 
          />
        </View>

        <View style={styles.inputGroup}>
          <Text style={styles.label}>Valor</Text>
          <TextInput 
            placeholder="" 
            style={styles.input} 
            keyboardType="numeric" 
            value={monto} 
            onChangeText={setMonto} 
          />
        </View>

        <TouchableOpacity style={styles.btn} onPress={guardar}>
          <Text style={styles.btnTxt}>Guardar Movimiento</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.btnCancelar} onPress={() => router.back()}>
          <Text style={styles.txtCancelar}>Cancelar</Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  content: { padding: 30, flex: 1, justifyContent: 'center' },
  titulo: { fontSize: 28, fontWeight: 'bold', marginBottom: 40, color: '#333', textAlign: 'center' },
  label: { fontSize: 14, color: '#888', marginBottom: 8, fontWeight: '600' },
  selector: { flexDirection: 'row', backgroundColor: '#F4F7FA', borderRadius: 15, padding: 6, marginBottom: 30 },
  opt: { flex: 1, padding: 12, alignItems: 'center', borderRadius: 12 },
  optTxt: { fontWeight: 'bold', color: '#666' },
  inputGroup: { marginBottom: 25 },
  input: { borderBottomWidth: 2, borderBottomColor: '#eee', fontSize: 20, paddingVertical: 8, color: '#333' },
  btn: { backgroundColor: '#007AFF', padding: 18, borderRadius: 15, alignItems: 'center', marginTop: 20, elevation: 3 },
  btnTxt: { color: '#fff', fontWeight: 'bold', fontSize: 16 },
  btnCancelar: { marginTop: 20, alignItems: 'center' },
  txtCancelar: { color: '#ff4d4d', fontWeight: '600' }
});