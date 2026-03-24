import { Box, Icon, Stack } from '../../components';

/**
 * Верхняя панель: состояние платы, счётчики, масштаб, краткая легенда управления.
 */
export const CircuitToolbar = (props) => {
  const {
    circuitOn,
    componentCount,
    variableCount,
    zoomPercent,
  } = props;

  const powered = circuitOn !== false && circuitOn !== 0;

  return (
    <Box className="IntegratedCircuit__toolbar">
      <Stack align="center" wrap="wrap">
        <Stack.Item>
          <Box
            className={powered
              ? 'IntegratedCircuit__chip IntegratedCircuit__chip--on'
              : 'IntegratedCircuit__chip IntegratedCircuit__chip--off'}>
            <Icon name="power-off" style={{ 'margin-right': '0.35em' }} />
            {powered ? 'Плата вкл.' : 'Плата выкл.'}
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Box className="IntegratedCircuit__chip IntegratedCircuit__chip--muted">
            <Icon name="microchip" style={{ 'margin-right': '0.35em' }} />
            Компонентов: <b>{componentCount}</b>
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Box className="IntegratedCircuit__chip IntegratedCircuit__chip--muted">
            <Icon name="database" style={{ 'margin-right': '0.35em' }} />
            Переменных: <b>{variableCount}</b>
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Box className="IntegratedCircuit__chip IntegratedCircuit__chip--muted">
            <Icon name="search-plus" style={{ 'margin-right': '0.35em' }} />
            Масштаб: <b>{zoomPercent}</b>%
          </Box>
        </Stack.Item>
        <Stack.Item grow className="IntegratedCircuit__legendWrap">
          <Box
            className="IntegratedCircuit__legend"
            title={
              'Поле: перетаскивание ЛКМ, масштаб — колёсико мыши. '
              + 'Нода: перетаскивание за заголовок. '
              + 'Связь: ЛКМ от выхода (справа) ко входу (слева). '
              + 'Снять связь: ПКМ по порту. '
              + 'Несколько проводов на вход: кнопки ⇄ меняют порядок.'
            }>
            <Icon
              name="mouse-pointer"
              style={{ 'margin-right': '0.35em', opacity: 0.75 }}
            />
            Поле · ЛКМ — сдвиг · колёсико — зум · связь выход→вход · ПКМ — снять
          </Box>
        </Stack.Item>
      </Stack>
    </Box>
  );
};
