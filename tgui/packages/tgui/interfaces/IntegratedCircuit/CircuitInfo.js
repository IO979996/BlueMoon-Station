import { Box, Button, Stack } from '../../components';

export const CircuitInfo = (props, context) => {
  const {
    name,
    desc,
    notices,
    ...rest
  } = props;
  const noticeList = notices || [];
  return (
    <Box {...rest}>
      <Stack fill vertical justify="space-around">
        {!!name && (
          <Stack.Item>
            <Box className="CircuitInfo__name">
              {name}
            </Box>
          </Stack.Item>
        )}
        <Stack.Item maxWidth="240px">
          <Box className="CircuitInfo__desc">
            {desc}
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Stack vertical>
            {noticeList.map((val, index) => (
              <Stack.Item key={index}>
                <Button
                  content={val.content}
                  color={val.color}
                  icon={val.icon}
                  fluid
                />
              </Stack.Item>
            ))}
          </Stack>
        </Stack.Item>
      </Stack>
    </Box>
  );
};
