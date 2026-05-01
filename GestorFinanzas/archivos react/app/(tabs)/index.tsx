import { Link } from 'expo-router';
import React from 'react';
import { SafeAreaView, ScrollView, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import { useUser } from './_layout';
import ProfileScreen from './perfil';

interface Movimiento {
  id: string;
  nombre: string;
  monto: number;
  tipo: 'ingreso' | 'gasto';
  fecha: string;
}

export default function HomeScreen() {
  const { userData, gastos } = useUser();

  if (!userData.inicializado) return <ProfileScreen />;

  const ingresos = gastos
    .filter((i: Movimiento) => i.tipo === 'ingreso')
    .reduce((a: number, b: Movimiento) => a + b.monto, 0);

  const egresos = gastos
    .filter((i: Movimiento) => i.tipo === 'gasto')
    .reduce((a: number, b: Movimiento) => a + b.monto, 0);

  const saldoActual = parseFloat(userData.monto) + ingresos - egresos;

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView showsVerticalScrollIndicator={false}>
        <View style={styles.header}>
          <Text style={styles.saludo}>Hola, {userData.nombre}</Text>
          <Text style={styles.saldoLabel}>Saldo Total Actual</Text>
          <Text style={styles.saldoMonto}>${saldoActual.toLocaleString('es-CO')}</Text>

          <View style={styles.row}>
            <View style={styles.cardResumen}>
              <Text style={styles.miniLabel}>Ingresos</Text>
              <Text style={styles.txtIngreso}>+${ingresos.toLocaleString()}</Text>
            </View>
            <View style={styles.cardResumen}>
              <Text style={styles.miniLabel}>Gastos</Text>
              <Text style={styles.txtGasto}>-${egresos.toLocaleString()}</Text>
            </View>
          </View>
        </View>

        <View style={styles.cuerpo}>
          <Text style={styles.tituloSec}>Actividad Reciente</Text>
          {gastos.map((item: Movimiento) => (
            <View key={item.id} style={styles.item}>
              <View style={[styles.icono, {backgroundColor: item.tipo === 'ingreso' ? '#e8f5e9' : '#ffebee'}]}>
                {/* Se quita el emoji y se deja un indicador de texto */}
                <Text style={{fontSize: 10, fontWeight: 'bold', color: item.tipo === 'ingreso' ? '#2ecc71' : '#e74c3c'}}>
                  {item.tipo === 'ingreso' ? 'INC' : 'EXP'}
                </Text>
              </View>
              <View style={{flex: 1}}>
                <Text style={styles.nombre}>{item.nombre}</Text>
                <Text style={styles.fecha}>{item.fecha}</Text>
              </View>
              <Text style={[styles.monto, {color: item.tipo === 'ingreso' ? '#2ecc71' : '#e74c3c'}]}>
                {item.tipo === 'ingreso' ? '+' : '-'}${item.monto.toLocaleString()}
              </Text>
            </View>
          ))}
        </View>
      </ScrollView>

      <Link href="/registro" asChild>
        <TouchableOpacity style={styles.fab}><Text style={styles.fabTxt}>+</Text></TouchableOpacity>
      </Link>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F4F7FA' },
  header: { backgroundColor: '#007AFF', padding: 25, paddingTop: 50, borderBottomLeftRadius: 40, borderBottomRightRadius: 40, elevation: 5 },
  saludo: { color: '#fff', fontSize: 18, opacity: 0.9 },
  saldoLabel: { color: '#fff', alignSelf: 'center', marginTop: 20, opacity: 0.7, fontSize: 14 },
  saldoMonto: { color: '#fff', fontSize: 38, fontWeight: 'bold', alignSelf: 'center' },
  row: { flexDirection: 'row', justifyContent: 'space-between', marginTop: 30 },
  cardResumen: { backgroundColor: '#fff', padding: 15, borderRadius: 20, width: '48%', elevation: 4 },
  miniLabel: { color: '#888', fontSize: 12, marginBottom: 4 },
  txtIngreso: { color: '#2ecc71', fontWeight: 'bold', fontSize: 16 },
  txtGasto: { color: '#e74c3c', fontWeight: 'bold', fontSize: 16 },
  cuerpo: { padding: 20 },
  tituloSec: { fontSize: 18, fontWeight: 'bold', marginBottom: 15, color: '#333' },
  item: { flexDirection: 'row', backgroundColor: '#fff', padding: 15, borderRadius: 20, alignItems: 'center', marginBottom: 12, elevation: 2 },
  icono: { width: 45, height: 45, borderRadius: 15, justifyContent: 'center', alignItems: 'center', marginRight: 15 },
  nombre: { fontWeight: 'bold', fontSize: 16, color: '#333' },
  fecha: { fontSize: 12, color: '#aaa' },
  monto: { fontWeight: 'bold', fontSize: 16 },
  fab: { position: 'absolute', bottom: 30, right: 25, backgroundColor: '#007AFF', width: 65, height: 65, borderRadius: 32.5, justifyContent: 'center', alignItems: 'center', elevation: 8 },
  fabTxt: { color: '#fff', fontSize: 35, fontWeight: '300' }
});